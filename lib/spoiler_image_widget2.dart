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

  void initializeOffsets(Rect rect) {
    spoilerBounds = rect;
    
    _controller.initParticles(rect, widget.configuration);
  }

  @override
  void initState() {
    _controller = SpoilerSpotsController(vsync: this);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SpoilerWidget oldWidget) {
    if (oldWidget.configuration != widget.configuration) {
      initializeOffsets(spoilerBounds);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPaint(Canvas canvas) {
    _controller.drawParticles(Offset.zero, canvas);
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
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, snapshot) {
          return CustomPaint(
            foregroundPainter: _ImageSpoilerPainter(
              currentRect: spoilerBounds,
              onBoundariesCalculated: initializeOffsets,
              onPaint: _onPaint,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                widget.child,
                ClipPath(
                  clipper: _OvalClipper(_controller.splashPathClipper),
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

class _ImageSpoilerPainter extends CustomPainter {
  final Rect currentRect;
  final ValueSetter<Rect> onBoundariesCalculated;
  final ValueSetter<Canvas> onPaint;
  const _ImageSpoilerPainter({
    required this.currentRect,
    required this.onBoundariesCalculated,
    required this.onPaint,
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
  bool shouldRepaint(_ImageSpoilerPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(_ImageSpoilerPainter oldDelegate) => false;
}

typedef OnClip = Path Function(Size size);

class _OvalClipper extends CustomClipper<Path> {
  final OnClip onClip;
  const _OvalClipper(this.onClip);
  @override
  Path getClip(Size size) => onClip.call(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => this != oldClipper;
}
