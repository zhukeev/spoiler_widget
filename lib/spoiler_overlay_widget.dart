import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_spots_controller.dart';
import 'package:spoiler_widget/models/widget_spoiler_config.dart';
import 'package:spoiler_widget/widgets/spoiler_render_object.dart';

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
          // Toggle the spoiler's visibility state through the controller.
          _spoilerController.toggle(details.localPosition);
        }
      },
      child: ListenableBuilder(
        listenable: _spoilerController,
        child: widget.child,
        builder: (context, child) {
          return SpoilerRenderObjectWidget(
            onAfterPaint: (canvas, size) => _onPaint(canvas, size),
            onClipPath: (size) {
              // If not fading (locked), return full path to show full spoiler overlay.
              if (_spoilerController.isEnabled && !_spoilerController.isFading) {
                return Path()..addRect(Offset.zero & size);
              }
              // During fade, return the punch-hole path (Intersect/Spot logic)
              // This creates a "Shrinking Spot" effect (Max Radius -> 0)
              // which matches SpoilerController's "Value 1 = Max Radius" logic.
              return _spoilerController.createClipPath(size);
            },
            enableOverlay: true,
            imageFilter: _spoilerController.isEnabled ? widget.config.imageFilter : null,
            child: child!,
          );
        },
      ),
    );
  }
}
