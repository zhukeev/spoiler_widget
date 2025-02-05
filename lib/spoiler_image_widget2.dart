import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
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
  late final SpoilerController _controller;

  void initializeOffsets(Rect rect) {
    _controller.initializeParticles([rect]);
  }

  @override
  void initState() {
    _controller = SpoilerController(
      particleColor: widget.configuration.particleColor,
      maxParticleSize: widget.configuration.maxParticleSize,
      fadeRadiusDeflate: widget.configuration.fadeRadius,
      speedOfParticles: widget.configuration.speedOfParticles,
      particleDensity: widget.configuration.particleDensity,
      fadeAnimationEnabled: widget.configuration.fadeAnimation,
      enableGesture: widget.configuration.enableGesture,
      initiallyEnabled: widget.configuration.isEnabled,
      vsync: this,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(covariant SpoilerWidget oldWidget) {
    if (oldWidget != widget) {
      _controller.disable();
    }

    if (oldWidget.configuration.isEnabled != widget.configuration.isEnabled) {
      _controller.onEnabledChanged(widget.configuration.isEnabled);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        if (widget.configuration.enableGesture) {
          _controller.toggle(details.localPosition);
        }
      },
      child: CustomPaint(
        painter: ImageSpoilerPainter(
          isEnabled: _controller.isEnabled,
          currentRect: _controller.spoilerBounds,
          onDrawParticles: (canvas) => _controller.drawParticles(Offset.zero, canvas),
          onBoundariesCalculated: initializeOffsets,
          repaint: _controller,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
         
            ImageFiltered(
              imageFilter: widget.configuration.imageFilter,
              enabled: _controller.fadeRadius > 0 || _controller.isEnabled,
              child: CustomPaint(
                foregroundPainter: HolePainter(
                  radius: _controller.fadeRadius,
                  center: _controller.fadeCenterOffset,
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
  final Rect currentRect;
  final ValueSetter<Rect> onBoundariesCalculated;
  final bool isEnabled;
  final void Function(Canvas canvas) onDrawParticles;
  const ImageSpoilerPainter({
    required this.isEnabled,
    required this.currentRect,
    required this.onBoundariesCalculated,
    required this.onDrawParticles,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final currentRect = Offset.zero & size;

    if (!isEnabled) {
      return;
    }

    if (this.currentRect != currentRect) {
      onBoundariesCalculated(currentRect);
    }

    onDrawParticles.call(canvas);
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
