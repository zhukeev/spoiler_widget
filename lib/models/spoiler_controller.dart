import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/utils/image_factory.dart';

import '../extension/rect_x.dart';
import '../models/particle.dart';

/// A base controller that manages a "spoiler" effect.
///
/// Key responsibilities:
/// 1. Managing a set of [Particle] objects (positions, movement, lifespan).
/// 2. Handling the fade animation (a radial reveal based on [_fadeCenterOffset]).
/// 3. Driving particle animation each tick (e.g., re-spawning dead particles or
///    moving particles in a random direction).
///
/// [SpoilerController] does not directly handle wave logic. Subclasses like
/// [SpoilerSpotsController] may add custom wave animations.
class SpoilerController extends ChangeNotifier {
  /// For spawning random positions and angles.
  final Random _random = Random();

  /// The [TickerProvider] necessary for animations (fade + particles).
  final TickerProvider _vsync;

  /// Animation for fade in/out transitions.
  AnimationController? _fadeAnimationController;
  Animation<double>? _fadeAnimation;

  /// Animation controller that drives the per-frame update of [particles].
  late AnimationController _particleAnimationController;

  /// Circle texture used to draw the particles with [drawRawAtlas].
  late ui.Image _circleImage;

  /// Returns `true` if there are particle objects in memory.
  bool get isInitialized => _particles.isNotEmpty;

  /// Whether the spoiler effect is currently enabled.
  bool get isEnabled => _isEnabled;

  /// Returns `true` if a fade animation is in progress.
  /// This is only meaningful if [SpoilerConfiguration.fadeAnimation] is `true`.
  bool get isFading =>
      _config.fadeAnimation && _fadeAnimationController != null && _fadeAnimationController!.isAnimating;

  /// A protected list of [Particle] objects. Subclasses like [SpoilerSpotsController]
  /// can modify them, but they’re hidden outside this library.
  @protected
  List<Particle> get particles => _particles;

  /// Internal storage of all active spoiler particles.
  final _particles = <Particle>[];

  /// Whether the spoiler is currently enabled or not.
  bool _isEnabled = false;

  /// The bounding area in which the spoiler effect is rendered.
  Rect get spoilerBounds => _spoilerBounds;
  Rect _spoilerBounds = Rect.zero;

  /// The path used for the "splash" reveal effect—i.e., a circle cut out of the rectangular spoiler area.
  /// This is used in your ClipPath or any custom painting that needs to represent the revealed region.
  Path get splashPath => Path.combine(
        PathOperation.difference,
        Path()..addRect(spoilerBounds),
        Path()
          ..addOval(
            Rect.fromCircle(
              center: _fadeCenterOffset,
              radius: _fadeRadius,
            ),
          ),
      );

  /// A path function that clips only the circular fade area if there’s a non-zero fadeRadius.
  Path splashPathClipper(Size size) {
    if (_fadeRadius == 0) {
      return Path()..addRect(Offset.zero & size);
    }
    return Path.combine(
      PathOperation.intersect,
      Path()..addRect(spoilerBounds),
      Path()
        ..addOval(
          Rect.fromCircle(
            center: _fadeCenterOffset,
            radius: _fadeRadius,
          ),
        ),
    );
  }

  /// A path that excludes the unselected area (XOR with the spoiler bounds).
  Path get excludeUnselectedPath => Path.combine(
        PathOperation.xor,
        _spoilerPath,
        Path()..addRect(spoilerBounds),
      );

  /// The path containing the bounding region of the spoiler.
  final _spoilerPath = Path();

  /// Used for the fade animation's radius. As the fade anim progresses, it grows
  /// from 0 to the bounding rect's farthest corner from [_fadeCenterOffset].
  double _fadeRadius = 0;

  /// The center of the fade animation circle. Toggling the spoiler calls
  /// [toggle(fadeOffset)] to set this point.
  Offset _fadeCenterOffset = Offset.zero;

  // Reusable atlas buffers to reduce allocations
  Float32List? _transforms;
  Float32List? _rects;
  Int32List? _colors;

  /// The config object used for both fade animations and particle generation.
  SpoilerConfiguration _config = SpoilerConfiguration.defaultConfig();

  /// Constructs a new [SpoilerController], initializing the particle animation
  /// controller immediately.
  SpoilerController({
    required TickerProvider vsync,
  }) : _vsync = vsync {
    _initAnimations();
  }

  /// Creates and configures the base animation controllers (but does not start them).
  void _initAnimations() {
    // Particle animation for updating positions over time.
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: _vsync,
    )..addListener(_onParticleTick);
  }

  /// Lazily initializes the fade animation if [fadeAnimation] is enabled in the config.
  void _initFadeIfNeeded() {
    if (_config.fadeAnimation && _fadeAnimationController == null) {
      _fadeAnimationController = AnimationController(
        value: isEnabled ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        vsync: _vsync,
      );
      _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeAnimationController!)
        ..addListener(_updateFadeRadius);
    }
  }

  /// Computes the current fade radius based on the fade animation's value.
  /// The idea is: if the fade animation is at 0, radius = 0. If at 1, radius
  /// = distance to the bounding rect's farthest corner from [_fadeCenterOffset].
  void _updateFadeRadius() {
    if (spoilerBounds == Rect.zero || _fadeAnimation == null) {
      return;
    }

    final farthestPoint = spoilerBounds.getFarthestPoint(_fadeCenterOffset);
    final distance = (farthestPoint - _fadeCenterOffset).distance;
    _fadeRadius = distance * _fadeAnimation!.value;
    notifyListeners();
  }

  /// Called every tick (via [_particleAnimationController]) to update or respawn particles.
  void _onParticleTick() {
    if (_particles.isEmpty) return;

    for (int index = 0; index < _particles.length; index++) {
      final offset = _particles[index];

      // If near the end of its life, respawn at a new random location.
      // Otherwise, let it continue moving in a random direction.
      _particles[index] = offset.life <= 0.1 ? _randomParticle(offset.rect) : offset.moveToRandomAngle();
    }

    // Because particle positions changed, we notify listeners so they can rebuild
    // or repaint.
    notifyListeners();
  }

  /// Starts the particle animation if the spoiler is enabled.
  void _startIfNeeded() {
    if (_isEnabled) {
      _particleAnimationController.repeat();
    }
  }

  /// Helper method to extract bounding [Rect]s from a given [Path].
  List<Rect> _getRects(Path path) {
    final rects = <Rect>[];
    for (final metric in path.computeMetrics()) {
      final Path contourPath = metric.extractPath(0, metric.length);
      rects.add(contourPath.getBounds());
    }
    return rects;
  }

  /// Initializes the [particles], the bounding path, and the circle image
  /// used to draw each particle. If the spoiler is configured to be enabled,
  /// this will also start the particle animation.
  ///
  /// [path] defines the region in which particles exist.
  /// [config] holds the fade/pixel density/particle size color, etc.
  void initializeParticles(Path path, SpoilerConfiguration config) {
    assert(config.maxParticleSize >= 1, 'Max particle size must be >= 1');
    _spoilerBounds = path.getBounds();

    _particles.clear();
    _spoilerPath.reset();
    _config = config;

    // Create the circle texture for all particles (used in _drawRawAtlas).
    _circleImage = CircleImageFactory.create(
      diameter: _config.maxParticleSize,
      color: _config.particleColor,
    );

    // Whether the spoiler is on or off at initialization
    _isEnabled = config.isEnabled;

    // If fade is enabled, ensure we have a fade animation controller
    _initFadeIfNeeded();

    // If the path is made up of multiple rects, add them individually
    final rects = _getRects(path);
    for (final rect in rects) {
      _spoilerPath.addRect(rect);

      // The number of particles is roughly (width + height) * density,
      // so bigger bounding areas get more particles.
      final count = (rect.width + rect.height) * _config.particleDensity;
      for (int index = 0; index < count; index++) {
        _particles.add(_randomParticle(rect));
      }
    }

    _reallocAtlasBuffers(); // create or update atlas buffers

    // If config says it’s enabled, start particle updates.
    _startIfNeeded();
  }

  void _reallocAtlasBuffers() {
    final count = _particles.length;
    _transforms = Float32List(count * 4);
    _rects = Float32List(count * 4);
    _colors = Int32List(count);
  }

  /// Creates a new [Particle] with random location/velocity inside [rect].
  Particle _randomParticle(Rect rect) {
    final offset = rect.deflate(_config.fadeRadius).randomOffset();
    return Particle(
      offset.dx,
      offset.dy,
      _config.maxParticleSize,
      _config.particleColor,
      _random.nextDouble(), // life
      _config.speedOfParticles,
      _random.nextDouble() * 2 * pi, // angle
      rect,
    );
  }

  /// Enables the spoiler effect (e.g., shows the content, triggers the fade
  /// from 0→1 if configured, and restarts particle movement).
  void enable() {
    _isEnabled = true;
    _particleAnimationController.repeat();
    _fadeAnimationController?.forward();
    notifyListeners();
  }

  /// Disables the spoiler effect (e.g., covers the content).
  /// - If fade animation is present, we animate it back to 0 and then stop everything.
  /// - Otherwise, we stop immediately.
  void disable() {
    if (_config.fadeAnimation == false) {
      // If no fade is configured, stop right away.
      _stopAll();
    } else {
      _fadeAnimationController!.reverse().whenCompleteOrCancel(() => _stopAll());
    }
  }

  /// Toggles spoiler on or off. Optionally accepts a [fadeOffset] that sets the
  /// center point for the reveal/fade circle.
  ///
  /// If the spoiler is off, [enable()] is called; otherwise, [disable()] is called.
  ///
  /// Subclasses may override this to intercept or add extra logic.
  void toggle([Offset? fadeOffset]) {
    if (isFading) return;

    _fadeCenterOffset = fadeOffset ?? Offset.zero;
    onEnabledChanged(!_isEnabled);
  }

  /// Called by [toggle] to handle the actual on/off logic.
  /// If [isFading] is true, we skip toggling to avoid mid-fade conflicts.
  void onEnabledChanged(bool value) {
    if (value) {
      enable();
    } else {
      disable();
    }
  }

  /// Stops all animations/timers and resets the fade radius. Does *not* clear
  /// the list of particles, but sets [isEnabled] to false.
  void _stopAll() {
    _isEnabled = false;
    _fadeRadius = 0;
    _particleAnimationController.reset();
    notifyListeners();
  }

  /// Draws all the particles in a single pass via [canvas.drawRawAtlas].
  ///
  /// [offset] shifts the particle positions on the canvas. Usually this is
  /// the global offset of the widget.
  void drawParticles(Offset offset, Canvas canvas) {
    // If the particle controller isn’t animating, skip.
    if (_particleAnimationController.status.isDismissed) return;
    // If the atlas buffers haven’t been created, skip.
    if (_transforms == null || _rects == null || _colors == null) return;
    _drawRawAtlas(offset, canvas);
  }

  /// Internal: populates [transforms], [rects], and [colors] arrays, then calls
  /// [canvas.drawRawAtlas] to render all particles.
  void _drawRawAtlas(Offset offset, Canvas canvas) {

    int index = 0;
    for (final point in _particles) {
      final pointWOffset = point + offset;
      final transformIndex = index * 4;

      if (isFading) {
        // Check if this particle is within the fading circle
        final distance = (_fadeCenterOffset - point).distance;
        if (distance < _fadeRadius) {
          // Slightly enlarge the particle near the fade boundary, turning them white
          // if they’re close to the edge.
          final scale = (distance > _fadeRadius - 20) ? 1.5 : 1.0;
          final color = (distance > _fadeRadius - 20) ? Colors.white : point.color;

          _transforms![transformIndex] = scale; // scaleX
          _transforms![transformIndex + 1] = 0.0; // rotation
          _transforms![transformIndex + 2] = pointWOffset.dx; // translateX
          _transforms![transformIndex + 3] = pointWOffset.dy; // translateY

          _rects![transformIndex] = 0.0; // left
          _rects![transformIndex + 1] = 0.0; // top
          _rects![transformIndex + 2] = _circleImage.width.toDouble(); // right
          _rects![transformIndex + 3] = _circleImage.height.toDouble(); // bottom

          _colors![index] = color.value;
          index++;
        } else {
          _colors![index] = Colors.transparent.value;
          index++;
        }
      } else {
        // If not fading, draw it normally.
        _transforms![transformIndex] = 1.0;
        _transforms![transformIndex + 1] = 0.0;
        _transforms![transformIndex + 2] = pointWOffset.dx;
        _transforms![transformIndex + 3] = pointWOffset.dy;

        _rects![transformIndex] = 0.0;
        _rects![transformIndex + 1] = 0.0;
        _rects![transformIndex + 2] = _circleImage.width.toDouble();
        _rects![transformIndex + 3] = _circleImage.height.toDouble();

        _colors![index] = point.color.value;
        index++;
      }
    }

    if (index > 0) {
      // Draw the final batch of active particles
      canvas.drawRawAtlas(
        _circleImage,
        _transforms!,
        _rects!,
        _colors!,
        BlendMode.srcOver,
        null, // cullRect
        Paint(),
      );
    }
  }

  @override
  void dispose() {
    // Dispose the main controllers for fade and particle updates.
    _particleAnimationController.dispose();
    _fadeAnimationController?.dispose();
    super.dispose();
  }
}
