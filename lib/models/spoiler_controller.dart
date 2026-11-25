import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/path_x.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/particle.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/spoiler_drawing_strategy.dart';

typedef SpoilerLogCallback = void Function(String message);

@visibleForTesting
SpoilerLogCallback debugSpoilerLogger = debugPrint;

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

  // ---------------------------------------------------------------------------
  // Drawing Strategy
  // ---------------------------------------------------------------------------
  late SpoilerDrawer _drawer;
  ParticleRenderBackend _particleRenderBackend = ParticleRenderBackend.atlas;
  bool _atlasUnavailable = false;
  bool _loggedAtlasFallback = false;
  bool _atlasDisabledByPolicy = false;

  /// Tracks if we've already tried to load the shader to avoid repeated attempts.
  bool _shaderInitAttempted = false;

  // ---------------------------
  // Caching
  // ---------------------------
  Path? _cachedClipPath;
  bool _isDisposed = false;

  // ---------------------------
  // Visual Assets & Bounds
  // ---------------------------
  /// The bounding area where particles are rendered.
  Rect _spoilerBounds = Rect.zero;

  /// A Path describing the spoiler region (may be multiple rectangles).
  final Path _spoilerPath = Path();

  /// Explicit list of rectangles for per-rect shader rendering.
  List<Rect> _spoilerRects = [];

  /// A radial fade reveals or hides content starting from this center offset.
  Offset _fadeCenter = Offset.zero;

  /// How large the fade circle is. As the fade anim progresses, this grows/shrinks.
  double _fadeRadius = 0;

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
    _drawer = _createDefaultParticleDrawer();
  }

  // ---------------------------------------------------------------------------
  // Public Getters
  // ---------------------------------------------------------------------------
  /// True if the active drawer has content to render.
  bool get isInitialized => _drawer.hasContent;

  /// The active particle rendering backend (shader, atlas, or vector).
  ParticleRenderBackend get renderBackend => _particleRenderBackend;

  /// Number of particles currently managed by the drawer.
  ///
  /// Returns 0 when a procedural shader backend is active.
  int get particleCount => _drawer.particles.length;

  @visibleForTesting
  ParticleRenderBackend get debugParticleRenderBackend => renderBackend;

  @visibleForTesting
  bool get debugAtlasUnavailable => _atlasUnavailable;

  @visibleForTesting
  bool get debugAtlasDisabledByPolicy => _atlasDisabledByPolicy;

  /// Particle list exposed for consumers like [SpoilerSpotsController].
  @protected
  List<Particle> get particles => _drawer.particles;

  /// The [TickerProvider] passed to the constructor, exposed for subclasses
  /// that run their own animations (e.g. [SpoilerSpotsController] waves).
  @protected
  TickerProvider get tickerProvider => _tickerProvider;

  /// True if the spoiler effect is currently on (particles + fade).
  bool get isEnabled => _isEnabled;

  /// True if the fade animation is active.
  bool get isFading =>
      _config.fadeConfig != null && _fadeCtrl != null && _fadeCtrl!.isAnimating;

  /// The bounding rectangle for the spoiler region.
  Rect get spoilerBounds => _spoilerBounds;

  Rect get _splashRect =>
      Rect.fromCircle(center: _fadeCenter, radius: _fadeRadius);

  /// A path function that clips only the circular fade area if there’s a non-zero fade radius.
  Path createClipPath(Size size) {
    final fade = _config.fadeConfig;
    if (fade == null || _fadeRadius == 0) {
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
      _splashRect == Rect.zero || _config.fadeConfig == null
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
  void initializeParticles(Path path, SpoilerConfig config,
      {List<Rect>? rects}) {
    final previousShaderPath = _config.shaderConfig?.customShaderPath;
    final nextShaderPath = config.shaderConfig?.customShaderPath;

    // Ensure maxParticleSize is valid
    assert(config.particleConfig.maxParticleSize >= 1,
        'maxParticleSize must be >= 1');
    final atlasPolicy = atlasSupportPolicyFor(config.particleConfig);
    _config = config;
    _spoilerRects = rects ?? [];
    _cachedClipPath = null; // Invalidate cache
    _atlasDisabledByPolicy = !atlasPolicy.isEligible;

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

    // Materialize sub-paths once — each subPaths iteration re-extracts
    // paths via computeMetrics, so iterating the lazy iterable repeatedly
    // would redo that work per consumer.
    final subPaths = _spoilerPath.subPaths.toList();

    // If rects weren't provided, approximate them from sub-path bounds.
    if (_spoilerRects.isEmpty) {
      _spoilerRects = subPaths.map((p) => p.getBounds()).toList();
    }

    _initFadeIfNeeded();

    // If shader changed (or removed), allow re-init and fall back to atlas while loading.
    if (previousShaderPath != nextShaderPath) {
      _shaderInitAttempted = false;
      if (_drawer is ShaderSpoilerDrawer || nextShaderPath == null) {
        _replaceDrawer(_createDefaultParticleDrawer(), disposeCurrent: true);
      }
    }

    if (_drawer is! ShaderSpoilerDrawer) {
      final particleDrawer = _ensureParticleDrawer();
      particleDrawer.initializeParticles(
        paths: subPaths,
        config: _config,
      );
      _validateAtlasAvailability(particleDrawer);
    }

    _isEnabled = config.isEnabled;
    _startParticleAnimationIfNeeded();

    // Attempt to switch to shader if configured
    if (_config.shaderConfig?.customShaderPath != null) {
      _initShaderIfNeeded();
    }
  }

  void updateConfiguration(SpoilerConfig config) {
    initializeParticles(_spoilerPath, config);
  }

  /// If fade animation is enabled, create the controller (once).
  void _initFadeIfNeeded() {
    if (_config.fadeConfig != null && _fadeCtrl == null) {
      _fadeCtrl = AnimationController(
        value: _config.isEnabled ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        vsync: _tickerProvider,
      );
      _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_fadeCtrl!)
        ..addListener(_updateFadeRadius);
    }
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
    if (_config.fadeConfig != null) {
      _fadeCtrl?.forward();
    }
    notifyListeners();
  }

  /// Turn off the spoiler effect: fade from 1→0, then stop the animation entirely.
  void disable() {
    if (_config.fadeConfig == null) {
      // If fade is disabled, just stop everything now.
      _stopAll();
    } else {
      final future = _fadeCtrl?.reverse();
      if (future == null) {
        _stopAll();
      } else {
        future.whenCompleteOrCancel(() => _stopAll());
      }
    }
  }

  /// Toggle the spoiler effect on/off. Optional [fadeOffset] for the radial center.
  bool toggle(Offset fadeOffset) {
    // If we’re mid-fade, skip to avoid partial toggles.
    if ((_config.fadeConfig != null && isFading) ||
        !_spoilerPath.contains(fadeOffset)) {
      return false;
    }

    // Record the offset from which the radial fade expands.
    setFadeCenter(fadeOffset);

    _onEnabledChanged(!_isEnabled);

    return true;
  }

  void setFadeCenter(Offset fadeCenter) {
    _fadeCenter = _spoilerBounds == Rect.zero
        ? fadeCenter
        : _spoilerBounds.getNearestPoint(fadeCenter);
    _cachedClipPath = null;
    if (_fadeAnim != null) {
      _updateFadeRadius();
    }
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

  /// Tracks the last seen [_particleCtrl] value so frame deltas can be
  /// converted into real elapsed seconds regardless of display refresh rate.
  double _lastParticleValue = 0.0;

  /// Called each frame (via [_particleCtrl]) to move or re-spawn particles.
  void _onParticleFrameTick() {
    final value = _particleCtrl.value;
    var delta = value - _lastParticleValue;
    if (delta < 0) {
      delta += 1.0; // wrap-around when repeat() restarts the cycle
    }
    _lastParticleValue = value;

    // [_particleCtrl] has a 1s duration, so the value delta is the elapsed
    // time in seconds. Clamp to avoid spiral-of-death jumps after hitches.
    final dt =
        (delta * _particleCtrl.duration!.inMicroseconds / 1e6).clamp(0.0, 0.1);
    _drawer.update(dt);
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
    if (_isDisposed) return;
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
  /// to [Canvas.drawRawAtlas] for optimal batched rendering.
  void drawParticles(Canvas canvas) {
    // If particle updates aren't running, skip drawing
    if (_particleCtrl.status.isDismissed) return;
    // Fallback? (or main draw now)
    // Create context
    final context = SpoilerContext(
      isFading: isFading,
      fadeRadius: _fadeRadius,
      fadeCenter: _fadeCenter,
      spoilerBounds: _spoilerBounds,
      spoilerRects: _spoilerRects,
      config: _config,
    );
    try {
      _drawer.draw(canvas, context);
    } catch (error, stackTrace) {
      if (_drawer is! AtlasSpoilerDrawer) {
        rethrow;
      }

      final fallbackDrawer = _downgradeAtlasDrawer(
        error,
        stackTrace,
      );
      fallbackDrawer.draw(canvas, context);
    }
  }

  /// Lazily initializes the shader renderer.
  Future<void> _initShaderIfNeeded() async {
    final path = _config.shaderConfig?.customShaderPath;
    if (path == null) return;

    // If we are already using a shader drawer for this path, we might not need to reload.
    // For now, simple check: if we already attempted and have a drawer, skip?
    // User might have changed config path, so we should allow re-init if path changed.
    // Simplest is to check boolean flag but reset it on config change.
    if (_shaderInitAttempted) return;
    _shaderInitAttempted = true;

    try {
      final shaderDrawer = await ShaderSpoilerDrawer.create(path);
      if (_isDisposed) return;
      _replaceDrawer(shaderDrawer, disposeCurrent: true);
      // Force a repaint now that we have the shader ready
      notifyListeners();
      debugPrint('SpoilerController: Switched to ShaderSpoilerDrawer');
    } catch (e) {
      debugPrint('SpoilerController: Failed to load shader: $e');
      // Fallback/stay on Atlas
    }
  }

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _isDisposed = true;
    // Dispose the main particle animation & fade controller if it exists.
    _particleCtrl.dispose();
    _fadeCtrl?.dispose();
    _drawer.dispose();
    super.dispose();
  }

  ParticleSpoilerDrawer _createDefaultParticleDrawer() {
    final drawer = (_atlasUnavailable || _atlasDisabledByPolicy)
        ? VectorSpoilerDrawer()
        : AtlasSpoilerDrawer();
    _particleRenderBackend = drawer.backend;
    return drawer;
  }

  ParticleSpoilerDrawer _ensureParticleDrawer() {
    final bool needsVector = _atlasUnavailable || _atlasDisabledByPolicy;

    if (_drawer is ParticleSpoilerDrawer) {
      final currentDrawer = _drawer as ParticleSpoilerDrawer;
      final isAtlas = currentDrawer is AtlasSpoilerDrawer;

      // If policy and current drawer backend match, reuse it.
      if (isAtlas != needsVector) {
        _particleRenderBackend = currentDrawer.backend;
        return currentDrawer;
      }
    }

    final drawer = _createDefaultParticleDrawer();
    _replaceDrawer(drawer, disposeCurrent: true);
    return drawer;
  }

  void _replaceDrawer(
    SpoilerDrawer drawer, {
    required bool disposeCurrent,
  }) {
    final previous = _drawer;
    _drawer = drawer;

    if (drawer is ShaderSpoilerDrawer) {
      _particleRenderBackend = ParticleRenderBackend.shader;
    } else if (drawer is ParticleSpoilerDrawer) {
      _particleRenderBackend = drawer.backend;
    }

    if (disposeCurrent && !identical(previous, drawer)) {
      previous.dispose();
    }
  }

  void _validateAtlasAvailability(ParticleSpoilerDrawer drawer) {
    if (drawer is! AtlasSpoilerDrawer) {
      return;
    }

    try {
      drawer.ensureSprite();
    } catch (error, stackTrace) {
      _downgradeAtlasDrawer(
        error,
        stackTrace,
        failedDrawer: drawer,
      );
    }
  }

  VectorSpoilerDrawer _downgradeAtlasDrawer(
    Object error,
    StackTrace _, {
    AtlasSpoilerDrawer? failedDrawer,
  }) {
    if (_drawer is VectorSpoilerDrawer && _atlasUnavailable) {
      return _drawer as VectorSpoilerDrawer;
    }

    _atlasUnavailable = true;
    final atlasDrawer = failedDrawer ?? _drawer as AtlasSpoilerDrawer;
    final vectorDrawer = VectorSpoilerDrawer()..adoptStateFrom(atlasDrawer);
    _replaceDrawer(vectorDrawer, disposeCurrent: false);
    atlasDrawer.dispose();
    if (!_loggedAtlasFallback) {
      _loggedAtlasFallback = true;
      debugSpoilerLogger(
        'SpoilerController: Atlas rendering disabled at runtime; using '
        'vector fallback instead. Error: $error',
      );
    }
    return vectorDrawer;
  }
}
