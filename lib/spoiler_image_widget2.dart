import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_spots_controller.dart';
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
  late final SpoilerSpotsController _controller;

  Rect spoilerBounds = Rect.zero;

  Offset fadeOffset = Offset.zero;

  void initializeOffsets(Rect rect) {
    spoilerBounds = rect;

    _controller.initParticles(rect);
  }

  @override
  void initState() {
    _controller = SpoilerSpotsController(
      particleColor: widget.configuration.particleColor,
      maxParticleSize: widget.configuration.maxParticleSize,
      fadeRadiusDeflate: widget.configuration.fadeRadius,
      speedOfParticles: widget.configuration.speedOfParticles,
      particleDensity: widget.configuration.particleDensity,
      fadeAnimationEnabled: widget.configuration.fadeAnimation,
      enableGesture: widget.configuration.enableGesture,
      initiallyEnabled: widget.configuration.isEnabled,
      maxActiveWaves: widget.configuration.maxActiveWaves,
      vsync: this,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(covariant SpoilerWidget oldWidget) {
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
          fadeOffset = details.localPosition;

          _controller.toggle(fadeOffset);
        }
      },
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, snapshot) {
          return CustomPaint(
            foregroundPainter: ImageSpoilerPainter(
              currentRect: spoilerBounds,
              onBoundariesCalculated: initializeOffsets,
              onPaint: (canvas) {
                _controller.drawParticles(Offset.zero, canvas);
              },
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                widget.child,
                ClipPath(
                  clipper: OvalClipper(_controller.splashPathClipper),
                  child: ImageFiltered(
                    imageFilter: widget.configuration.imageFilter,
                    enabled: _controller.isEnabled,
                    child: snapshot!,
                  ),
                ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class ImageSpoilerPainter extends CustomPainter {
  final Rect currentRect;
  final ValueSetter<Rect> onBoundariesCalculated;
  final ValueSetter<Canvas> onPaint;
  const ImageSpoilerPainter({
    required this.currentRect,
    required this.onBoundariesCalculated,
    required this.onPaint,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final currentRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (this.currentRect != currentRect) {
      onBoundariesCalculated(currentRect);
    }

    onPaint(canvas);
  }

  @override
  bool shouldRepaint(ImageSpoilerPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(ImageSpoilerPainter oldDelegate) => false;
}

class OvalClipper extends CustomClipper<Path> {
  final Path path;
  const OvalClipper(this.path);
  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => this != oldClipper;
}
