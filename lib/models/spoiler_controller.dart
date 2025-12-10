import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/path_x.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/utils/image_factory.dart';
import 'package:spoiler_widget/utils/spoiler_shader_renderer.dart';

import '../extension/rect_x.dart';
import '../models/particle.dart';

/// A base controller that manages a "spoiler" effect, which involves:
/// 1. A set of "particles" (positions, movement, lifespan).
/// 2. An optional fade animation (a radial reveal or cover based on [_fadeCenter]).
/// 3. Regular particle updates (re-spawning or random movement).
///
/// This class does *not* handle wave animations (see [SpoilerSpotsController] for that).
///
/// USAGE:
///  - Instantiate with a [TickerProvider], which is typically your State object.
///  - Call [initializeParticles] to set up the bounding path, the configuration (e.g. fade, color, speed).
///  - Use [toggle], [enable], or [disable] to turn the spoiler effect on/off.
///  - In your painting code, call [drawParticles] to render the moving particles.
class SpoilerController extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Used to generate random positions, angles, and lifespans for particles.
  final Random _random = Random();

  /// Provides Tickers for our AnimationControllers (fade + particles).
  final TickerProvider _tickerProvider;

  // ---------------------------
  // Fade Animation
  // ---------------------------
  AnimationController? _fadeCtrl;
  Animation<double>? _fadeAnim;

  /// Whether the spoiler is currently enabled (shown) or not.
  bool _isEnabled = false;

  // ---------------------------
  // Particle Animation
  // ---------------------------
  /// Controls per-frame updates for all particles.
  late final AnimationController _particleCtrl;

  /// Internal list of active particles in the spoiler region.
  @protected
  final List<Particle> particles = [];

  // ---------------------------
  // Atlas / Drawing Buffers
  // ---------------------------
  /// Reused for transform data in drawRawAtlas.
  Float32List? _atlasTransforms;

  /// Reused for texture coordinates (rect data) in drawRawAtlas.
  Float32List? _atlasRects;

  /// Reused for color data in drawRawAtlas.
  Int32List? _atlasColors;

  // ---------------------------
  // Shader Rendering
  // ---------------------------
  /// Custom shader renderer if [SpoilerConfig.customShaderPath] is set.
  SpoilerShaderRenderer? _shaderRenderer;
  bool _shaderInitAttempted = false;
  double _shaderTime = 0;

  // ---------------------------
  // Caching
  // ---------------------------
  Path? _cachedClipPath;

  // ---------------------------
  // Visual Assets & Bounds
  // ---------------------------
  /// The bounding area where particles are rendered.
  Rect _spoilerBounds = Rect.zero;

  /// A Path describing the spoiler region (may be multiple rectangles).
  final Path _spoilerPath = Path();

  /// Cached list of sub-paths (individual text blocks) for per-rect shader rendering.
  // TODO: Deprecate/remove if _spoilerRects replaces this completely.
  // Keeping for fallback or if Path based logic is needed elsewhere.
  List<Path> _encapsulatedPaths = [];

  /// Explicit list of rectangles for per-rect shader rendering.
  List<Rect> _spoilerRects = [];

  /// A radial fade reveals or hides content starting from this center offset.
  Offset _fadeCenter = Offset.zero;

  /// How large the fade circle is. As the fade anim progresses, this grows/shrinks.
  double _fadeRadius = 0;

  /// A 2D texture to draw each particle (a circle image).
  CircleImage _circleImage = CircleImageFactory.create(diameter: 1, color: Colors.white);

  // ---------------------------
  // Configuration
  // ---------------------------
  SpoilerConfig _config = SpoilerConfig.defaultConfig();

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  /// Creates a new [SpoilerController].
  ///
  /// [vsync] is the TickerProvider (e.g., your [State] or [SingleTickerProviderStateMixin]).
  SpoilerController({
    required TickerProvider vsync,
  }) : _tickerProvider = vsync {
    _initAnimationControllers();
  }

  // ---------------------------------------------------------------------------
  // Public Getters
  // ---------------------------------------------------------------------------
  /// True if we have at least one particle.
  bool get isInitialized => particles.isNotEmpty;

  /// True if the spoiler effect is currently on (particles + fade).
  bool get isEnabled => _isEnabled;

  /// True if the fade animation is active.
  bool get isFading => _config.enableFadeAnimation && _fadeCtrl != null && _fadeCtrl!.isAnimating;

  /// The bounding rectangle for the spoiler region.
  Rect get spoilerBounds => _spoilerBounds;

  Rect get _splashRect => Rect.fromCircle(center: _fadeCenter, radius: _fadeRadius);

  /// A path function that clips only the circular fade area if there’s a non-zero fade radius.
  Path createClipPath(Size size) {
    if (!_config.enableFadeAnimation || _fadeRadius == 0) {
      return _spoilerPath;
    }
    return Path.combine(
      PathOperation.intersect,
      _spoilerPath,
      Path()..addOval(_splashRect),
    );
  }

  Path createSplashPathMaskClipper(Size size) {
    // show black screen while initializing
    if (!isInitialized) {
      return Path();
    }

    if (_cachedClipPath != null) {
      return _cachedClipPath!;
    }

    final clippedSpoilerPath = Path.combine(
      PathOperation.intersect,
      // If the fade radius is 0 or the fade animation is disabled, we clip to the entire spoiler region.
      _splashRect == Rect.zero || !_config.enableFadeAnimation
          ? (Path()..addRect(spoilerBounds))
          : (Path()..addOval(_splashRect)),
      _spoilerPath,
    );

    final finalClipPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      clippedSpoilerPath,
    );

    _cachedClipPath = finalClipPath;
    return finalClipPath;
  }

  // ---------------------------------------------------------------------------
  // Setup & Particle Initialization
  // ---------------------------------------------------------------------------
  /// Creates our two main AnimationControllers:
  ///  - [_particleCtrl] for per-frame particle updates
  ///  - [_fadeCtrl] is lazily created if fadeAnimation is enabled.
  void _initAnimationControllers() {
    // Particle controller: updates once per frame to move or respawn particles.
    _particleCtrl = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: _tickerProvider,
    )..addListener(_onParticleFrameTick);
  }

  /// Initializes the particle system with necessary bounds and configuration.
  ///
  /// [path]: The area where particles can exist (e.g. text outlines).
  /// [config]: Configuration for speed, density, color, etc.
  /// [rects]: Optional explicit list of rectangles (e.g. for individual words).
  ///          If provided, this is preferred for shader rendering to ensure precise per-rect shapes.
  void initializeParticles(Path path, SpoilerConfig config, {List<Rect>? rects}) {
    // Ensure maxParticleSize is valid
    assert(config.maxParticleSize >= 1, 'maxParticleSize must be >= 1');
    _config = config;
    _spoilerRects = rects ?? [];
    particles.clear();
    _cachedClipPath = null; // Invalidate cache

    if (_spoilerPath != path) {
      _spoilerPath.reset();
      if (config.maskConfig != null) {
        final newPath = Path.combine(
          config.maskConfig!.maskOperation,
          path,
          config.maskConfig!.maskPath.shift(
            config.maskConfig!.offset,
          ),
        );
        _spoilerPath.addPath(newPath, Offset.zero);
      } else {
        _spoilerPath.addPath(path, Offset.zero);
      }
      _spoilerBounds = _spoilerPath.getBounds();
    }

    // If rects weren't provided, try to approximate them from path bounds
    if (_spoilerRects.isEmpty) {
      // Fallback: use subPaths derived rects
      // This keeps backward compatibility if initializeParticles is called without rects
      // Note: subPaths getter can be expensive, computed once here.
      final subPaths = _spoilerPath.subPaths;
      _encapsulatedPaths = subPaths.toList();
      _spoilerRects = _encapsulatedPaths.map((p) => p.getBounds()).toList();
    } else {
      // If rects provided, we should probably still populate _encapsulatedPaths
      // if we want to support the old particle system correctly?
      // The old system iterates subPaths.
      // If the path passed in is just a union of rects, subPaths should work fine.
      // So we leave the loop related to particles generation as is, using _spoilerPath.subPaths.
    }

    _initFadeIfNeeded();

    if (_circleImage.color != _config.particleColor || _circleImage.dimension != _config.maxParticleSize) {
      _circleImage = CircleImageFactory.create(
        diameter: _config.maxParticleSize,
        color: _config.particleColor,
      );
    }

    // Re-generate particles (cpu) regardless of shader model
    // This allows fallback if shader fails
    final subPaths = _spoilerPath.subPaths;
    _encapsulatedPaths = subPaths.toList();

    for (final path in subPaths) {
      final rect = path.getBounds();
      final particleCount = (rect.width * rect.height) * _config.particleDensity;
      for (int i = 0; i < particleCount; i++) {
        particles.add(_createRandomParticlePath(path));
      }
    }

    _isEnabled = config.isEnabled;

    _reallocAtlasBuffers();

    _startParticleAnimationIfNeeded();
  }

  void updateConfiguration(SpoilerConfig config) {
    initializeParticles(_spoilerPath, config);
  }

  /// If fade animation is enabled, create the controller (once).
  void _initFadeIfNeeded() {
    if (_config.enableFadeAnimation && _fadeCtrl == null) {
      _fadeCtrl = AnimationController(
        value: _config.isEnabled ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        vsync: _tickerProvider,
      );
      _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_fadeCtrl!)..addListener(_updateFadeRadius);
    }
  }

  /// Reallocate or expand the atlas buffers if the particle count changed.
  void _reallocAtlasBuffers() {
    final count = particles.length;
    _atlasTransforms = Float32List(count * 4);
    _atlasRects = Float32List(count * 4);
    _atlasColors = Int32List(count);
  }

  Particle _createRandomParticlePath(Path path) {
    final offset = path.getRandomPoint();
    return Particle(
      offset.dx,
      offset.dy,
      _config.maxParticleSize,
      _config.particleColor,
      _random.nextDouble(), // life
      _config.particleSpeed, // velocity
      _random.nextDouble() * 2 * pi, // angle
      path,
    );
  }

  // ---------------------------------------------------------------------------
  // Public Control Methods
  // ---------------------------------------------------------------------------

  /// Turn on the spoiler effect: show the fade from 0→1 (if configured),
  /// and restart the particle animation.
  void enable() {
    _isEnabled = true;
    _cachedClipPath = null; // Invalidate cache
    _startParticleAnimationIfNeeded();
    if (_config.enableFadeAnimation) {
      _fadeCtrl?.forward();
    }
    notifyListeners();
  }

  /// Turn off the spoiler effect: fade from 1→0, then stop the animation entirely.
  void disable() {
    if (!_config.enableFadeAnimation) {
      // If fade is disabled, just stop everything now.
      _stopAll();
    } else {
      _fadeCtrl?.reverse().whenCompleteOrCancel(() => _stopAll());
    }
  }

  /// Toggle the spoiler effect on/off. Optional [fadeOffset] for the radial center.
  bool toggle(Offset fadeOffset) {
    // If we’re mid-fade, skip to avoid partial toggles.
    if ((_config.enableFadeAnimation && isFading) || !_spoilerPath.contains(fadeOffset)) {
      return false;
    }

    // Record the offset from which the radial fade expands.
    setFadeCenter(fadeOffset);

    _onEnabledChanged(!_isEnabled);

    return true;
  }

  void setFadeCenter(Offset fadeCenter) {
    _fadeCenter = fadeCenter;
  }

  /// Called by [toggle] after setting [_fadeCenter].
  /// If [value] is true, calls [enable]. Otherwise, [disable].
  void _onEnabledChanged(bool value) {
    if (value) {
      enable();
    } else {
      disable();
    }
    _config.onSpoilerVisibilityChanged?.call(value);
  }

  // ---------------------------------------------------------------------------
  // Internal Particle Update & Fade
  // ---------------------------------------------------------------------------

  /// If _isEnabled is true, start or repeat the particle animation loop.
  void _startParticleAnimationIfNeeded() {
    if (_isEnabled) {
      _particleCtrl.repeat();
    }
  }

  /// Called each frame (via [_particleCtrl]) to move or re-spawn particles.
  void _onParticleFrameTick() {
    // If using custom shader, update time uniform
    if (_config.customShaderPath != null) {
      // 60 FPS approx increment.
      // Ideally we'd use elapsed time from the Ticker, but this is sufficient for visual effects.
      _shaderTime += 0.016;
      notifyListeners();
    }

    if (particles.isEmpty) return;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      // If near end of life, spawn a new particle. Otherwise, keep moving.
      particles[i] = (p.life <= 0.1) ? _createRandomParticlePath(p.path) : p.moveToRandomAngle();
    }
    notifyListeners();
  }

  /// Recomputes _fadeRadius whenever the fade animation changes.
  void _updateFadeRadius() {
    if (_spoilerBounds == Rect.zero || _fadeAnim == null) return;

    // Distance to the farthest corner from _fadeCenter
    final farthestPoint = _spoilerBounds.getFarthestPoint(_fadeCenter);
    final distance = (farthestPoint - _fadeCenter).distance;

    // If fadeAnim goes from 0→1, we scale radius from 0→distance
    _fadeRadius = distance * _fadeAnim!.value;
    _cachedClipPath = null; // Invalidate cache
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Stopping Everything
  // ---------------------------------------------------------------------------

  /// Fully stops the spoiler effect: sets isEnabled=false, resets fade radius,
  /// and stops the particle animation.
  void _stopAll() {
    _isEnabled = false;
    _fadeRadius = 0;
    _cachedClipPath = null; // Invalidate cache
    _particleCtrl.reset();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Drawing
  // ---------------------------------------------------------------------------

  /// Draws the current set of particles.
  ///
  /// Uses shader rendering if enabled and available, otherwise falls back
  /// to [canvas.drawRawAtlas] for optimal batched rendering.
  void drawParticles(Canvas canvas) {
    // If particle updates aren't running, skip drawing
    if (_particleCtrl.status.isDismissed) return;

    // Update shader time
    _shaderTime += 0.016; // ~60fps increment

    // Try shader rendering if enabled
    if (_config.customShaderPath != null) {
      _initShaderIfNeeded();
      if (_shaderRenderer != null) {
        _drawParticlesWithShader(canvas);
        return;
      }
    }

    // Fallback to atlas rendering
    if (_atlasTransforms == null || _atlasRects == null || _atlasColors == null) {
      return;
    }

    _drawParticlesWithRawAtlas(canvas);
  }

  /// Lazily initializes the shader renderer.
  void _initShaderIfNeeded() {
    if (_shaderInitAttempted) return;
    _shaderInitAttempted = true;

    final path = _config.customShaderPath;
    if (path == null) return;

    SpoilerShaderRenderer.create(path).then((renderer) {
      _shaderRenderer = renderer;
      if (renderer != null) {
        debugPrint('SpoilerController: Custom shader loaded from $path');
      }
    });
  }

  /// Draws particles using the custom shader.
  void _drawParticlesWithShader(Canvas canvas) {
    if (_spoilerRects.isEmpty) {
      // Fallback if no rects (e.g. initial frame or simple box)
      canvas.save();

      if (isFading && _fadeRadius > 0) {
        final circlePath = Path()
          ..addOval(
            Rect.fromCircle(center: _fadeCenter, radius: _fadeRadius),
          );
        final clipPath = Path.combine(
          PathOperation.intersect,
          _spoilerPath,
          circlePath,
        );
        canvas.clipPath(clipPath);
      } else {
        // canvas.clipPath(_spoilerPath);
        // Allow bleeding for "smooth edge" effect
      }

      final params = _config.onGetShaderUniforms?.call(_spoilerBounds, _shaderTime, 0.0, _config) ?? [];

      _shaderRenderer!.render(
        canvas,
        _spoilerBounds.inflate(_config.fadeRadius),
        _shaderTime,
        seed: 0.0,
        params: params,
      );
      canvas.restore();
      return;
    }

    int i = 0;
    for (final rect in _spoilerRects) {
      // Generate a unique, stable seed for this rect index and position
      // This ensures "Hello" has diverse noise from "World", but consistent over time.
      final seed = i * 123.45 + rect.left + rect.top;

      canvas.save();

      if (isFading && _fadeRadius > 0) {
        // Geometric Clipping:
        // We want to draw particles INSIDE the fade circle (Ink Spreader effect),
        // covering the text which is masked out by the clipper.
        final rectPath = Path()..addRect(rect);
        final circlePath = Path()
          ..addOval(
            Rect.fromCircle(center: _fadeCenter, radius: _fadeRadius),
          );

        final clipPath = Path.combine(
          PathOperation.intersect,
          rectPath,
          circlePath,
        );

        canvas.clipPath(clipPath);
      } else {
        // canvas.clipRect(rect);
        // Allow bleeding
      }

      final params = _config.onGetShaderUniforms?.call(rect, _shaderTime, seed, _config) ?? [];

      _shaderRenderer!.render(
        canvas,
        rect.inflate(_config.maxParticleSize),
        _shaderTime,
        seed: seed,
        params: params,
      );

      canvas.restore();
      i++;
    }
  }

  /// Populates [transforms], [rects], [colors] for each particle, then calls [canvas.drawRawAtlas].
  void _drawParticlesWithRawAtlas(Canvas canvas) {
    final transforms = _atlasTransforms!;
    final rects = _atlasRects!;
    final colors = _atlasColors!;

    int index = 0;
    for (final p in particles) {
      final transformIndex = index * 4;
      final pointOffset = p;

      if (isFading) {
        // If we have a fade, check if the particle is inside the fade circle
        final distSq = (_fadeCenter - p).distanceSquared;
        final radiusSq = _fadeRadius * _fadeRadius;

        if (distSq < radiusSq) {
          // Enlarge near the edge, turning them white if close to radius boundary
          // We approximate the "edge" check with squares to avoid sqrt if possible,
          // or just take sqrt once if needed. Let's stick to simple logic but optimized.
          // Actually, let's keep it simple for now but using distanceSquared for the main check.

          // Re-calculating distance only if inside for the "edge" effect
          final dist = sqrt(distSq);

          final scale = (dist > _fadeRadius - 20) ? 1.5 : 1.0;
          final color = (dist > _fadeRadius - 20) ? Colors.white : p.color;

          transforms[transformIndex + 0] = scale;
          transforms[transformIndex + 1] = 0.0;
          transforms[transformIndex + 2] = pointOffset.dx;
          transforms[transformIndex + 3] = pointOffset.dy;

          rects[transformIndex + 0] = 0.0;
          rects[transformIndex + 1] = 0.0;
          rects[transformIndex + 2] = _circleImage.dimension.toDouble();
          rects[transformIndex + 3] = _circleImage.dimension.toDouble();
          // ignore: deprecated_member_use
          colors[index] = color.value;
          index++;
        } else {
          // If outside the circle, just hide the particle
          // ignore: deprecated_member_use
          colors[index] = Colors.transparent.value;
          transforms[transformIndex + 0] = 0;

          index++;
        }
      } else {
        // Normal (non-fading) scenario
        transforms[transformIndex + 0] = 1.0;
        transforms[transformIndex + 1] = 0.0;
        transforms[transformIndex + 2] = pointOffset.dx;
        transforms[transformIndex + 3] = pointOffset.dy;

        rects[transformIndex + 0] = 0.0;
        rects[transformIndex + 1] = 0.0;
        rects[transformIndex + 2] = _circleImage.dimension.toDouble();
        rects[transformIndex + 3] = _circleImage.dimension.toDouble();

        // ignore: deprecated_member_use
        colors[index] = p.color.value;
        index++;
      }
    }

    // If index>0, we have something to draw
    if (index > 0) {
      canvas.drawRawAtlas(
        _circleImage.image,
        transforms,
        rects,
        colors,
        BlendMode.srcOver,
        null, // cullRect
        _particlePaint,
      );
    }
  }

  final Paint _particlePaint = Paint();

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    // Dispose the main particle animation & fade controller if it exists.
    _particleCtrl.dispose();
    _fadeCtrl?.dispose();
    super.dispose();
  }
}
