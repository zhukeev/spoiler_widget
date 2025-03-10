import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_spots_controller.dart';
import 'package:spoiler_widget/models/widget_spoiler.dart';
import 'package:spoiler_widget/widgets/canvas_callback_painter.dart';

class SpoilerOverlay extends StatefulWidget {
  const SpoilerOverlay({
    super.key,
    required this.child,
    required this.config,
  });
  final Widget child;
  final WidgetSpoilerConfig config;

  @override
  State<SpoilerOverlay> createState() => _SpoilerOverlayState();
}

class _SpoilerOverlayState extends State<SpoilerOverlay> with TickerProviderStateMixin {
  late final SpoilerSpotsController _spoilerController = SpoilerSpotsController(vsync: this);
  Rect _spoilerBounds = Rect.zero;

  void _initializeSpoilerBounds(Size size) {
    _spoilerBounds = Rect.fromLTWH(0, 0, size.width, size.height);
    _spoilerController.initParticles(_spoilerBounds, widget.config);
  }

  @override
  void didUpdateWidget(covariant SpoilerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _initializeSpoilerBounds(_spoilerBounds.size);
    }
  }

  @override
  void dispose() {
    _spoilerController.dispose();
    super.dispose();
  }

  void _onPaint(Canvas canvas, Size size) {
    final currentBounds = Rect.fromLTWH(0, 0, size.width, size.height);
    if (_spoilerBounds != currentBounds) {
      _initializeSpoilerBounds(size);
    }
    _spoilerController.drawParticles(canvas);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        if (widget.config.enableGestureReveal) {
          _spoilerController.toggle(details.localPosition);
        }
      },
      child: ListenableBuilder(
        listenable: _spoilerController,
        builder: (context, snapshot) {
          return Stack(
            alignment: Alignment.center,
            children: [
              widget.child,
              CustomPaint(
                foregroundPainter: CustomPainterCanvasCallback(onPaint: _onPaint),
                child: ClipPath(
                  clipper: _SpoilerClipper(_spoilerController.createClipPath),
                  child: ImageFiltered(
                    imageFilter: widget.config.imageFilter,
                    enabled: _spoilerController.isEnabled,
                    child: widget.child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

typedef ClipPathBuilder = Path Function(Size size);

class _SpoilerClipper extends CustomClipper<Path> {
  final ClipPathBuilder clipPathBuilder;

  const _SpoilerClipper(this.clipPathBuilder);

  @override
  Path getClip(Size size) => clipPathBuilder.call(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => this != oldClipper;
}
