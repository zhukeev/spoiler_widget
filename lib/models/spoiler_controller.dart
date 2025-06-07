import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/path_x.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/utils/image_factory.dart';

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
  // Visual Assets & Bounds
  // ---------------------------
  /// The bounding area where particles are rendered.
  Rect _spoilerBounds = Rect.zero;

  /// A Path describing the spoiler region (may be multiple rectangles).
  final Path _spoilerPath = Path();

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
    return Path.combine(
      PathOperation.intersect,
      _spoilerPath,
      _fadeCenter == Offset.zero || !_config.enableFadeAnimation ? _spoilerPath : (Path()..addOval(_splashRect)),
    );
  }

  Path createSplashPathMaskClipper(Size size) {
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

  /// Sets up the spoiler region, the bounding path, and initializes all particles.
  /// If [config.isEnabled] is true, the spoiler is turned on, and we start the particle animation.
  ///
  /// [path] is the shape describing where particles should exist.
  /// [config] includes fade, density, maxParticleSize, etc.
  void initializeParticles(Path path, SpoilerConfig config) {
    // Ensure maxParticleSize is valid
    assert(config.maxParticleSize >= 1, 'maxParticleSize must be >= 1');
    _config = config;
    particles.clear();

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

    _initFadeIfNeeded();

    if (_circleImage.color != _config.particleColor || _circleImage.dimension != _config.maxParticleSize) {
      _circleImage = CircleImageFactory.create(
        diameter: _config.maxParticleSize,
        color: _config.particleColor,
      );
    }

    final subPaths = _spoilerPath.subPaths;

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
      _fadeCtrl?.toggle().whenCompleteOrCancel(() => _stopAll());
    }
  }

  /// Toggle the spoiler effect on/off. Optional [fadeOffset] for the radial center.
  bool toggle(Offset fadeOffset) {
    // If we’re mid-fade, skip to avoid partial toggles.
    if ((_config.enableFadeAnimation && isFading) || !_spoilerPath.contains(fadeOffset)) return false;

    // Record the offset from which the radial fade expands.
    _fadeCenter = fadeOffset;

    onEnabledChanged(!_isEnabled);

    return true;
  }

  /// Called by [toggle] after setting [_fadeCenter].
  /// If [value] is true, calls [enable]. Otherwise, [disable].
  void onEnabledChanged(bool value) {
    if (value) {
      enable();
    } else {
      disable();
    }
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
    if (particles.isEmpty) return;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      // If near end of life, spawn a new particle. Otherwise, keep moving.
      // particles[i] = (p.life <= 0.1) ? _createRandomParticle(p.rect) : p.moveToRandomAngle();
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
    _particleCtrl.reset();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Drawing
  // ---------------------------------------------------------------------------

  /// Draws the current set of particles via [canvas.drawRawAtlas].
  void drawParticles(Canvas canvas) {
    // If particle updates aren’t running, skip drawing
    if (_particleCtrl.status.isDismissed) return;

    // If atlas buffers are uninitialized, skip
    if (_atlasTransforms == null || _atlasRects == null || _atlasColors == null) return;

    _drawParticlesWithRawAtlas(canvas);
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
        final dist = (_fadeCenter - p).distance;

        if (dist < _fadeRadius) {
          // Enlarge near the edge, turning them white if close to radius boundary
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

          colors[index] = color.value;
          index++;
        } else {
          // If outside the circle, just hide the particle
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
        Paint(),
      );
    }
  }

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
