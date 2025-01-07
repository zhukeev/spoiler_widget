import 'dart:async';
import 'dart:math' hide log;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/particle.dart';
import 'package:spoiler_widget/models/widget_spoiler.dart';

class SpoilerWidget extends StatefulWidget {
  const SpoilerWidget({
    super.key,
    required this.child,
    required this.configuration,
  });
  final Widget child;
  final WidgetSpoilerConfiguration configuration;

  @override
  State createState() => _SpoilerWidgetState();
}

class _SpoilerWidgetState extends State<SpoilerWidget> with TickerProviderStateMixin {
  final rnd = Random();

  AnimationController? fadeAnimationController;
  Animation<double>? fadeAnimation;
  Timer? timer;
  ui.Image? circleImage;

  late final AnimationController particleAnimationController;
  late final Animation<double> particleAnimation;
  final waveAnimationControllers = <int, AnimationController>{};
  final particles = <int, Particle>{};
  bool enabled = false;
  Rect spoilerBounds = Rect.zero;
  double fadeRadius = 0;

  Offset fadeOffset = Offset.zero;

  Particle randomParticle(Rect rect) {
    final offset = rect.deflate(widget.configuration.fadeRadius).randomOffset();

    return Particle(
      offset.dx,
      offset.dy,
      widget.configuration.maxParticleSize,
      widget.configuration.particleColor,
      rnd.nextDouble(),
      widget.configuration.speedOfParticles,
      rnd.nextDouble() * 2 * pi,
      rect,
    );
  }

  void initializeOffsets(Rect rect) {
    particles.clear();
    spoilerBounds = rect;

    debugPrint('initializeOffsets $spoilerBounds');

    final count = (rect.width + rect.height) * widget.configuration.particleDensity * 2;

    for (int index = 0; index < count; index++) {
      particles[index] = randomParticle(rect);
    }

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        Future.delayed(Duration(milliseconds: Random().nextInt(3000)), _randomWaveAnimation);
        Future.delayed(Duration(milliseconds: Random().nextInt(3000)), _randomWaveAnimation);
        Future.delayed(Duration(milliseconds: Random().nextInt(3000)), _randomWaveAnimation);
      },
    );
  }

  void updateRadius() {
    final farthestPoint = spoilerBounds.getFarthestPoint(fadeOffset);

    final distance = (farthestPoint - fadeOffset).distance;

    final progress = (fadeAnimation?.value ?? 1);
    if (progress == 0) return;

    fadeRadius = distance * progress;
  }

  @override
  void initState() {
    particleAnimationController = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    particleAnimation = Tween<double>(begin: 0, end: 1).animate(particleAnimationController)..addListener(_myListener);

    if (widget.configuration.fadeAnimation) {
      fadeAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      fadeAnimation = Tween<double>(begin: 0, end: 1).animate(fadeAnimationController!)..addListener(updateRadius);
    }

    enabled = widget.configuration.isEnabled;

    if (enabled) {
      _onEnabledChanged(widget.configuration.isEnabled);
    }

    createCircleImage(color: widget.configuration.particleColor, diameter: widget.configuration.maxParticleSize).then(
      (val) {
        setState(() {
          circleImage = val;
        });
      },
    );

    super.initState();
  }

  void _myListener() {
    setState(
      () {
        for (int index = 0; index < particles.length - 1; index++) {
          final offset = particles[index];

          // If particle is dead, replace it with a new one
          // Otherwise, move it
          particles[index] = offset!.life <= 0.1 ? randomParticle(offset.rect) : offset.moveToRandomAngle();
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant SpoilerWidget oldWidget) {
    if (oldWidget != widget) {
      particles.clear();
    }

    if (oldWidget.configuration.isEnabled != widget.configuration.isEnabled) {
      _onEnabledChanged(widget.configuration.isEnabled);
    }

    super.didUpdateWidget(oldWidget);
  }

  void _onEnabledChanged(bool enable) {
    debugPrint('enable $enable');
    if (enable) {
      setState(() => enabled = true);
      particleAnimationController.repeat();
      fadeAnimationController?.forward();
    } else {
      if (fadeAnimationController == null) {
        stopAnimation();
      } else {
        fadeAnimationController!.toggle().whenCompleteOrCancel(() {
          stopAnimation();
        });
      }
    }
  }

  void stopAnimation() {
    setState(() {
      particles.clear();
      spoilerBounds = Rect.zero;
      enabled = false;
      timer?.cancel();
      timer = null;
      particleAnimationController.reset();
      for (final controller in waveAnimationControllers.values) {
        controller.dispose();
      }

      waveAnimationControllers.clear();
    });
  }

  @override
  void dispose() {
    particleAnimation.removeListener(_myListener);
    particleAnimationController.dispose();
    fadeAnimationController?.dispose();
    timer?.cancel();

    for (final controller in waveAnimationControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _randomWaveAnimation() {
    final offset = spoilerBounds.randomOffset();

    _waveAnimation(offset);
  }

  Future<ui.Image> createCircleImage({
    required double diameter,
    required Color color,
  }) async {
    assert(diameter.isFinite, 'Diameter cannot be infinite');
    assert(diameter >= 1, 'Diameter must be greater than or equal to 1');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;

    final radius = diameter / 2;
    canvas.drawCircle(Offset.zero, radius, paint);

    final picture = recorder.endRecording();
    return picture.toImage(diameter.toInt(), diameter.toInt());
  }

  void _waveAnimation(Offset offset) {
    if (!enabled || spoilerBounds == Rect.zero) return;

    final maxRadius = spoilerBounds.shortestSide ~/ 4;
    if (maxRadius == 0) return;
    final awayRadius = rnd.nextInt(maxRadius);
    final animationController = waveAnimationControllers[offset.hashCode] ??= AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    final curvedAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    for (int index = 0; index < particles.length; index++) {
      final current = particles[index]!;
      final distanceDiff = offset - current;
      final distanceDelta = distanceDiff.distance;

      if (distanceDelta >= awayRadius) continue;

      final direction = distanceDiff / distanceDelta;
      var possibleEndPoint = current.translate(
        -(awayRadius - distanceDelta) * direction.dx,
        -(awayRadius - distanceDelta) * direction.dy,
      );

      possibleEndPoint = spoilerBounds.containsOffset(possibleEndPoint)
          ? possibleEndPoint
          : spoilerBounds.getNearestPoint(possibleEndPoint);

      final randomAngle = rnd.nextDouble() * 2 * pi;
      final randomEndPoint = possibleEndPoint.translate(
        10 * cos(randomAngle),
        10 * sin(randomAngle),
      );

      final clampedRandomEndPoint = spoilerBounds.getNearestPoint(randomEndPoint);

      final anim = TweenSequence<Offset>([
        TweenSequenceItem(tween: Tween(begin: current, end: possibleEndPoint), weight: 50),
        TweenSequenceItem(tween: Tween(begin: possibleEndPoint, end: clampedRandomEndPoint), weight: 50),
      ]).animate(curvedAnimation);

      void waveAnimationListener() {
        if (!enabled || particles.isEmpty) return;
        particles[index] = current.copyWith(dx: anim.value.dx, dy: anim.value.dy);

        if (animationController.isCompleted) {
          anim.removeListener(waveAnimationListener);
          animationController.dispose();
          waveAnimationControllers.remove(offset.hashCode);
        }
      }

      anim.addListener(waveAnimationListener);
    }

    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        if (widget.configuration.enableGesture) {
          _onEnabledChanged(!enabled);
          fadeOffset = details.localPosition;
        }
      },
      child: CustomPaint(
        foregroundPainter: circleImage == null
            ? null
            : ImageSpoilerPainter(
                isEnabled: enabled,
                fadeRadius: fadeRadius,
                currentRect: spoilerBounds,
                tapOffset: fadeOffset,
                particles: particles.values.toList(),
                onBoundariesCalculated: initializeOffsets,
                repaint: particleAnimation,
                circleImage: circleImage!,
              ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            ImageFiltered(
              imageFilter: widget.configuration.imageFilter,
              enabled: (fadeAnimationController != null && fadeRadius > 0) || enabled,
              child: CustomPaint(
                foregroundPainter: HolePainter(
                  radius: fadeRadius,
                  center: fadeOffset,
                ),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageSpoilerPainter extends CustomPainter {
  final double fadeRadius;
  final Offset tapOffset;
  final Rect currentRect;
  final List<Particle> particles;
  final ValueSetter<Rect> onBoundariesCalculated;
  final bool isEnabled;
  final ui.Image circleImage;
  const ImageSpoilerPainter({
    required this.isEnabled,
    required this.currentRect,
    required this.fadeRadius,
    required this.onBoundariesCalculated,
    required this.tapOffset,
    required this.particles,
    required this.circleImage,
    super.repaint,
  });

  void _drawRawAtlas(bool isAnimating, Canvas canvas, double radius) {
    final int count = particles.length;
    final transforms = Float32List(count * 4);
    final rects = Float32List(count * 4);
    final colors = Int32List(count);

    int index = 0;
    for (final point in particles) {
      final transformIndex = index * 4;

      if (isAnimating) {
        final distance = (tapOffset - point).distance;

        if (distance < radius) {
          final scale = (distance > radius - 20) ? 1.5 : 1.0;
          final color = (distance > radius - 20) ? Colors.white : point.color;

          // Populate transform data
          transforms[transformIndex] = scale; // scaleX
          transforms[transformIndex + 1] = 0.0; // rotation
          transforms[transformIndex + 2] = point.dx; // translateX
          transforms[transformIndex + 3] = point.dy; // translateY

          // Populate rect data (assuming the circle texture is square)
          rects[transformIndex] = 0.0; // left
          rects[transformIndex + 1] = 0.0; // top
          rects[transformIndex + 2] = circleImage.width.toDouble(); // right
          rects[transformIndex + 3] = circleImage.height.toDouble(); // bottom

          // Populate color data (ARGB format as Int32)
          colors[index] = color.value;
          index++;
        }
      } else {
        // Populate transform data for non-animating particles
        transforms[transformIndex] = 1.0; // scaleX
        transforms[transformIndex + 1] = 0.0; // rotation
        transforms[transformIndex + 2] = point.dx; // translateX
        transforms[transformIndex + 3] = point.dy; // translateY

        // Populate rect data (assuming the circle texture is square)
        rects[transformIndex] = 0.0; // left
        rects[transformIndex + 1] = 0.0; // top
        rects[transformIndex + 2] = circleImage.width.toDouble(); // right
        rects[transformIndex + 3] = circleImage.height.toDouble(); // bottom

        // Populate color data (ARGB format as Int32)
        colors[index] = point.color.value;
        index++;
      }
    }

    // Draw all particles in one batch
    canvas.drawRawAtlas(
      circleImage,
      transforms,
      rects,
      colors,
      BlendMode.srcOver,
      null, // CullRect if needed
      Paint(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final currentRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (!isEnabled) {
      return;
    }

    if (this.currentRect != currentRect) {
      onBoundariesCalculated(currentRect);
    }

    final isAnimating = fadeRadius != 0 && fadeRadius != 1.0;

    _drawRawAtlas(isAnimating, canvas, fadeRadius);
  }

  @override
  bool shouldRepaint(ImageSpoilerPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(ImageSpoilerPainter oldDelegate) => false;
}

/// [HolePainter] provides a custom painter for leaving a circular hole with some
/// fuziness.
class HolePainter extends CustomPainter {
  final double radius;
  final Offset center;

  HolePainter({super.repaint, required this.radius, required this.center});
  @override
  void paint(Canvas canvas, Size size) {
    if (radius == 0) {
      return;
    }

    final path1 = Path()
      ..addOval(Rect.fromCircle(center: center, radius: size.longestSide))
      ..close();

    final path2 = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..close();

    final path3 = Path.combine(PathOperation.difference, path1, path2);

    canvas.drawPath(path3..close(), Paint()..blendMode = BlendMode.clear);
  }

  @override
  bool shouldRepaint(HolePainter oldDelegate) => oldDelegate.radius != radius || oldDelegate.center != center;
}
