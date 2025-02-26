import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:spoiler_widget/utils/image_factory.dart';

import '../extension/rect_x.dart';
import '../models/particle.dart';

/// A controller that encapsulates spoiler logic:
/// - Holds references to particles
/// - Manages fade/wave animations
/// - Knows how to create a circle image (texture for the particles)
/// - Exposes events so widgets can rebuild accordingly
class SpoilerController extends ChangeNotifier {
  final Random _random = Random();

  final TickerProvider vsync;

  // Animation controllers for particles & fade.
  AnimationController? _fadeAnimationController;
  Animation<double>? _fadeAnimation;

  late AnimationController _particleAnimationController;

  late final ui.Image _circleImage = CircleImageFactory.create(diameter: maxParticleSize, color: particleColor);
  Rect get fadeRect => Rect.fromCircle(center: fadeCenterOffset, radius: fadeRadius);

  bool get isInitialized => particles.isNotEmpty;

  bool get isEnabled => _isEnabled;

  // Particle data.
  final particles = <Particle>[];
  bool _isEnabled = false;

  // Bounds and offsets.
  Rect get spoilerBounds => _spoilerBounds;
  Rect _spoilerBounds = Rect.zero;
  final _spoilerPath = Path();

  double fadeRadius = 0;
  Offset fadeCenterOffset = Offset.zero;

  // External configuration. (We keep it generic so that
  // the same controller can be used for text or widgets.)
  final Color particleColor;
  final double maxParticleSize;
  final double fadeRadiusDeflate;
  final double speedOfParticles;
  final double particleDensity;
  final bool fadeAnimationEnabled;
  final bool enableGesture;

  SpoilerController({
    required this.particleColor,
    required this.maxParticleSize,
    required this.fadeRadiusDeflate,
    required this.speedOfParticles,
    required this.particleDensity,
    required this.fadeAnimationEnabled,
    required this.enableGesture,
    required this.vsync,
    bool initiallyEnabled = false,
  }) {
    assert(
      maxParticleSize.isFinite && maxParticleSize >= 1,
      'Invalid maxParticleSize',
    );
    _isEnabled = initiallyEnabled;
    _initAnimations();
    _initParticlesIfNeeded();
  }

  AnimationStatus get fadeStatus => _fadeAnimationController?.status ?? AnimationStatus.dismissed;

  bool get isFading =>
      fadeAnimationEnabled && _fadeAnimationController != null && _fadeAnimationController!.isAnimating;

  Path get splashPath => Path.combine(
        PathOperation.difference,
        Path()..addRect(spoilerBounds),
        Path()..addOval(Rect.fromCircle(center: fadeCenterOffset, radius: fadeRadius)),
      );

  Path  splashPathClipper(Size size) {
    if (fadeRadius == 0) return Path()..addRect(Offset.zero & size);

    return Path.combine(
      PathOperation.intersect,
      Path()..addRect(spoilerBounds),
      Path()..addOval(Rect.fromCircle(center: fadeCenterOffset, radius: fadeRadius)),
    );
  }

  Path get excludeUnselectedPath => Path.combine(
        PathOperation.xor,
        _spoilerPath,
        Path()..addRect(spoilerBounds),
      );

  /// Initialization of animations. Called from the constructor.
  void _initAnimations() {
    // Particle animation (e.g., 1 second, repeated).
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: vsync,
    )..addListener(_onParticleTick);

    // Fade animation if enabled
    if (fadeAnimationEnabled) {
      _fadeAnimationController = AnimationController(
        value: isEnabled ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        vsync: vsync,
      );
      _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeAnimationController!)
        ..addListener(_updateFadeRadius);
    }
  }

  /// Called when the fade animation updates, we recalc the current fade radius.
  void _updateFadeRadius() {
    if (spoilerBounds == Rect.zero || _fadeAnimation == null) {
      return;
    }
    final farthestPoint = spoilerBounds.getFarthestPoint(fadeCenterOffset);
    final distance = (farthestPoint - fadeCenterOffset).distance;
    fadeRadius = distance * _fadeAnimation!.value;
    notifyListeners();
  }

  /// Particle tick: move or respawn dead particles.
  void _onParticleTick() {
    if (particles.isEmpty) return;

    for (int index = 0; index < particles.length; index++) {
      final offset = particles[index];

      // If particle is dead, replace it with a new one
      // Otherwise, move it
      particles[index] = offset.life <= 0.1 ? _randomParticle(offset.rect) : offset.moveToRandomAngle();
    }

    notifyListeners();
  }

  /// Create or clear particles if needed.
  void _initParticlesIfNeeded() {
    if (_isEnabled) {
      _particleAnimationController.repeat();
    }
  }

  /// Initialize all particles for the bounding rectangle.
  void initializeParticles(List<Rect> rects) {
    _spoilerBounds = rects.getBounds();
    particles.clear();
    _spoilerPath.reset();

    for (final rect in rects) {
      _spoilerPath.addRect(rect);
      final count = (rect.width + rect.height) * particleDensity;

      for (int index = 0; index < count; index++) {
        particles.add(_randomParticle(rect));
      }
    }
  }

  /// Builds a new random particle in the given rect.
  Particle _randomParticle(Rect rect) {
    final offset = rect.deflate(fadeRadiusDeflate).randomOffset();
    return Particle(
      offset.dx,
      offset.dy,
      maxParticleSize,
      particleColor,
      _random.nextDouble(),
      speedOfParticles,
      _random.nextDouble() * 2 * pi,
      rect,
    );
  }

  /// Enable the spoiler effect (uncover).
  void enable() {
    _isEnabled = true;
    _particleAnimationController.repeat();
    _fadeAnimationController?.forward();
    notifyListeners();
  }

  /// Disable the spoiler effect (cover).
  void disable() {
    if (_fadeAnimationController == null) {
      // No fade animation - just immediately stop
      _stopAll();
    } else {
      _fadeAnimationController!.toggle().whenCompleteOrCancel(() => _stopAll());
    }
  }

  /// Toggle spoiler effect on/off.
  // void toggle() => isEnabled ? disable() : enable();
  void toggle([Offset? fadeOffset]) {
    fadeCenterOffset = fadeOffset ?? Offset.zero;
    onEnabledChanged(!_isEnabled);
  }

  void onEnabledChanged(bool value) {
    if (value) {
      enable();
    } else {
      disable();
    }
  }

  /// Stop all timers/animations and clear data.
  void _stopAll() {
    _isEnabled = false;
    fadeRadius = 0;
    _particleAnimationController.reset();
    notifyListeners();
  }

  void drawParticles(Offset offset, Canvas canvas) {
    if (_particleAnimationController.status.isDismissed) return;
    _drawRawAtlas(offset, canvas);
  }

  void _drawRawAtlas(Offset offset, Canvas canvas) {
    final int count = particles.length;
    final transforms = Float32List(count * 4);
    final rects = Float32List(count * 4);
    final colors = Int32List(count);

    int index = 0;
    for (final point in particles) {
      final pointWOffset = point + offset;
      final transformIndex = index * 4;

      if (isFading) {
        final distance = (fadeCenterOffset - point).distance;

        if (distance < fadeRadius) {
          final scale = (distance > fadeRadius - 20) ? 1.5 : 1.0;
          final color = (distance > fadeRadius - 20) ? Colors.white : point.color;

          // Populate transform data
          transforms[transformIndex] = scale; // scaleX
          transforms[transformIndex + 1] = 0.0; // rotation
          transforms[transformIndex + 2] = pointWOffset.dx; // translateX
          transforms[transformIndex + 3] = pointWOffset.dy; // translateY

          // Populate rect data (assuming the circle texture is square)
          rects[transformIndex] = 0.0; // left
          rects[transformIndex + 1] = 0.0; // top
          rects[transformIndex + 2] = _circleImage.width.toDouble(); // right
          rects[transformIndex + 3] = _circleImage.height.toDouble(); // bottom

          // Populate color data (ARGB format as Int32)
          colors[index] = color.value;
          index++;
        }
      } else {
        // Populate transform data for non-animating particles
        transforms[transformIndex] = 1.0; // scaleX
        transforms[transformIndex + 1] = 0.0; // rotation
        transforms[transformIndex + 2] = pointWOffset.dx; // translateX
        transforms[transformIndex + 3] = pointWOffset.dy; // translateY

        // Populate rect data (assuming the circle texture is square)
        rects[transformIndex] = 0.0; // left
        rects[transformIndex + 1] = 0.0; // top
        rects[transformIndex + 2] = _circleImage.width.toDouble(); // right
        rects[transformIndex + 3] = _circleImage.height.toDouble(); // bottom

        // Populate color data (ARGB format as Int32)
        colors[index] = point.color.value;

        index++;
      }
    }

    // Draw all particles in one batch
    canvas.drawRawAtlas(
      _circleImage,
      transforms,
      rects,
      colors,
      BlendMode.srcOver,
      null, // CullRect if needed
      Paint(),
    );
  }

  @override
  void dispose() {
    _particleAnimationController.dispose();
    _fadeAnimationController?.dispose();
    super.dispose();
  }
}
