import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/widgets/spoiler_render_object.dart';

/// High-level wrapper that:
///  - hides all text widgets in the subtree (Text / RichText),
///  - lets [SpoilerRenderObjectWidget] intercept painting,
///  - then renders custom spoiler particles + text via canvas.
///
/// You can wrap *any* widget tree (e.g. Column, ListView, custom layouts),
/// and all text inside will be "spoilered" without changing the tree manually.
class SpoilerTextWrapper extends StatefulWidget {
  const SpoilerTextWrapper({
    super.key,
    required this.child,
    required this.config,
  });

  final Widget child;
  final SpoilerConfig config;

  @override
  State<SpoilerTextWrapper> createState() => _SpoilerTextWrapperState();
}

class _SpoilerTextWrapperState extends State<SpoilerTextWrapper>
    with TickerProviderStateMixin {
  late final SpoilerController _spoilerController =
      SpoilerController(vsync: this);

  @override
  void didUpdateWidget(covariant SpoilerTextWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    final configChanged = oldWidget.config != widget.config;
    final childChanged = oldWidget.child != widget.child;

    if (configChanged || childChanged) {
      _spoilerController.updateConfiguration(widget.config);
    }
  }

  @override
  void dispose() {
    _spoilerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _spoilerController,
      child: widget.child,
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          if (widget.config.enableGestureReveal) {
            _spoilerController.toggle(details.localPosition);
          }
        },
        child: SpoilerRenderObjectWidget(
          onPaint: (canvas, size) {
            if (_spoilerController.isEnabled) {
              _spoilerController.drawParticles(canvas);
            }
          },
          onClipPath: (size) =>
              _spoilerController.createSplashPathMaskClipper(size),
          onInit: (rects) {
            final path = Path();
            for (final rect in rects) {
              path.addRect(rect);
            }
            _spoilerController.initializeParticles(path, widget.config,
                rects: rects);
          },
          child: child,
        ),
      ),
    );
  }
}
