import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/particle.dart';
import 'package:spoiler_widget/models/string_details.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/widgets/spoiler_richtext.dart';

class SpoilerTextWidget extends StatefulWidget {
  const SpoilerTextWidget({
    super.key,
    required this.text,
    required this.configuration,
  });

  final TextSpoilerConfiguration configuration;
  final String text;

  @override
  State createState() => _SpoilerTextWidgetState();
}

class _SpoilerTextWidgetState extends State<SpoilerTextWidget> with TickerProviderStateMixin {
  final rng = Random();

  AnimationController? fadeAnimationController;
  Animation<double>? fadeAnimation;

  late final AnimationController particleAnimationController;
  late final Animation<double> particleAnimation;
  List<Rect> spoilerRects = [];
  Rect spoilerBounds = Rect.zero;
  final particles = <Particle>[];
  bool enabled = false;

  Offset fadeOffset = Offset.zero;
  Path spoilerPath = Path();

  Particle randomParticle(Rect rect) {
    final offset = rect.deflate(widget.configuration.fadeRadius).randomOffset();

    return Particle(
      offset.dx,
      offset.dy,
      widget.configuration.maxParticleSize,
      widget.configuration.particleColor,
      rng.nextDouble(),
      widget.configuration.speedOfParticles,
      rng.nextDouble() * 2 * pi,
      rect,
    );
  }

  void initializeOffsets(StringDetails details) {
    particles.clear();
    spoilerPath.reset();

    spoilerRects = details.words.map((e) => e.rect.deflate(widget.configuration.fadeRadius)).toList();
    spoilerBounds = spoilerRects.getBounds();

    for (final word in details.words) {
      spoilerPath.addRect(word.rect);

      final count = (word.rect.width + word.rect.height) * widget.configuration.particleDensity;
      for (int index = 0; index < count; index++) {
        particles.add(randomParticle(word.rect));
      }
    }
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
      fadeAnimation = Tween<double>(begin: 0, end: 1).animate(fadeAnimationController!);
    }

    enabled = widget.configuration.isEnabled;

    if (enabled) {
      _onEnabledChanged(enabled);
    }

    super.initState();
  }

  void _myListener() {
    setState(
      () {
        for (int index = 0; index < particles.length; index++) {
          final offset = particles[index];

          // If particle is dead, replace it with a new one
          // Otherwise, move it
          particles[index] = offset.life <= 0.1 ? randomParticle(offset.rect) : offset.moveToRandomAngle();
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant SpoilerTextWidget oldWidget) {
    if (oldWidget.configuration.selection != widget.configuration.selection ||
        oldWidget.configuration.style != widget.configuration.style) {
      particles.clear();
    }

    if (oldWidget.configuration.isEnabled != widget.configuration.isEnabled) {
      _onEnabledChanged(widget.configuration.isEnabled);
    }

    super.didUpdateWidget(oldWidget);
  }

  void _onEnabledChanged(bool enable) {
    if (enable) {
      setState(() => enabled = true);
      particleAnimationController.repeat();
      fadeAnimationController?.forward();
    } else {
      if (fadeAnimationController == null) {
        stopAnimation();
      } else {
        fadeAnimationController!.reverse().whenCompleteOrCancel(() {
          stopAnimation();
        });
      }
    }
  }

  void stopAnimation() {
    setState(() {
      enabled = false;
      particleAnimationController.reset();
      particles.clear();
    });
  }

  @override
  void dispose() {
    particleAnimation.removeListener(_myListener);
    particleAnimationController.dispose();
    fadeAnimationController?.dispose();
    super.dispose();
  }

  late final TapGestureRecognizer _onTapRecognizer = TapGestureRecognizer()
    ..onTapUp = (details) {
      fadeOffset = details.localPosition;

      if (widget.configuration.enableGesture &&
          widget.configuration.selection != null &&
          spoilerRects.any((rect) => rect.contains(fadeOffset))) {
        setState(() {
          _onEnabledChanged(!enabled);
        });
      }
    };

  @override
  Widget build(BuildContext context) {
    return SpoilerRichText(
      onBoundariesCalculated: initializeOffsets,
      key: UniqueKey(),
      selection: widget.configuration.selection,
      onPaint: (context, offset, superPaint) {
        if (!enabled) {
          superPaint(context, offset);
          return;
        }

        final isAnimating = fadeAnimationController != null && fadeAnimationController!.isAnimating;

        late final double radius;

        void updateRadius() {
          final farthestPoint = spoilerBounds.getFarthestPoint(fadeOffset);

          final distance = (farthestPoint - (fadeOffset + offset)).distance;

          radius = distance * fadeAnimation!.value;
        }

        if (isAnimating) {
          updateRadius();
        }

        for (final point in particles) {
          final pointWOffset = point + offset;
          final paint = Paint()
            ..strokeWidth = point.size
            ..color = point.color
            ..style = PaintingStyle.fill;

          if (isAnimating) {
            final distance = (fadeOffset - point).distance;

            if (distance < radius) {
              context.canvas.drawCircle(
                pointWOffset,
                point.size * ((distance > radius - 20) ? 1.5 : 1),
                paint..color = (distance > radius - 20) ? Colors.white : point.color,
              );
            }
          } else {
            context.canvas.drawCircle(pointWOffset, point.size, paint);
          }
        }

        void drawSplashAnimation() {
          final rect = Rect.fromCircle(center: fadeOffset, radius: radius);

          final path = Path.combine(
            PathOperation.difference,
            Path()..addRect(spoilerBounds),
            Path()..addOval(rect),
          );

          context.pushClipPath(true, offset, spoilerBounds, path, superPaint);
        }

        if (isAnimating) {
          drawSplashAnimation();
        }

        if (widget.configuration.selection != null) {
          final path = Path.combine(
            PathOperation.difference,
            Path()..addRect(context.estimatedBounds),
            spoilerPath,
          );

          context.pushClipPath(true, offset, spoilerBounds, path, superPaint);
        }
      },
      initialized: particles.isNotEmpty,
      text: TextSpan(
        text: widget.text,
        recognizer: widget.configuration.enableGesture ? _onTapRecognizer : null,
        style: widget.configuration.style,
      ),
    );
  }
}
