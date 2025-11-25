import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/utils/text_hider.dart';
import 'package:spoiler_widget/widgets/spoiler_text_painter_multi.dart';

/// High-level wrapper that:
///  - hides all text widgets in the subtree (Text / RichText),
///  - lets [SpoilerTextPainterMulti] collect their layout/regions,
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

class _SpoilerTextWrapperState extends State<SpoilerTextWrapper> with TickerProviderStateMixin {
  late final SpoilerController _spoilerController = SpoilerController(vsync: this);

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

  /// Called when [SpoilerTextPainterMulti] recomputes text regions.
  void _setSpoilerRegions(List<Rect> regions) {
    final spoilerMaskPath = Path();
    for (final rect in regions) {
      spoilerMaskPath.addRect(rect);
    }

    _spoilerController.initializeParticles(spoilerMaskPath, widget.config);
  }

  @override
  Widget build(BuildContext context) {
    final Widget childWithHiddenText = hideTextInSubtree(widget.child);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        if (widget.config.enableGestureReveal) {
          _spoilerController.toggle(details.localPosition);
        }
      },
      child: SpoilerTextPainterMulti(
        onPaint: (canvas, size) {
          if (_spoilerController.isEnabled) {
            _spoilerController.drawParticles(canvas);

            canvas.clipPath(
              _spoilerController.createSplashPathMaskClipper(size),
            );
          }
        },
        onInit: _setSpoilerRegions,
        repaint: _spoilerController,
        child: childWithHiddenText,
      ),
    );
  }
}
