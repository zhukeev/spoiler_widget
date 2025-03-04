import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_spots_controller.dart';
import 'package:spoiler_widget/models/widget_spoiler.dart';
import 'package:spoiler_widget/widgets/canvas_callback_painter.dart';

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
  late final SpoilerSpotsController _controller = SpoilerSpotsController(vsync: this);

  Rect spoilerBounds = Rect.zero;

  void initializeOffsets(Rect rect) {
    spoilerBounds = rect;

    _controller.initParticles(rect, widget.configuration);
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

  void _onPaint(Canvas canvas, Size size) {
    final currentRect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (spoilerBounds != currentRect) {
      initializeOffsets(currentRect);
    }
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
            foregroundPainter: CustomPainterCanvasCallback(onPaint: _onPaint),
            child: Stack(
              children: [
                widget.child,
                ClipPath(
                  clipper: _OvalClipper(_controller.createClipPath),
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

typedef OnClip = Path Function(Size size);

class _OvalClipper extends CustomClipper<Path> {
  final OnClip onClip;
  const _OvalClipper(this.onClip);
  @override
  Path getClip(Size size) => onClip.call(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => this != oldClipper;
}
