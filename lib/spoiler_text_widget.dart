import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/widgets/spoiler_text_painter.dart';

class SpoilerText extends StatefulWidget {
  const SpoilerText({
    super.key,
    required this.text,
    required this.config,
  });

  final TextSpoilerConfig config;
  final String text;

  @override
  State<SpoilerText> createState() => _SpoilerTextState();
}

class _SpoilerTextState extends State<SpoilerText>
    with TickerProviderStateMixin {
  late final SpoilerController _spoilerController =
      SpoilerController(vsync: this);

  void _setSpoilerRegions(List<Rect> regions) {
    final Path spoilerMaskPath = Path();
    for (final rect in regions) {
      spoilerMaskPath.addRect(rect);
    }
    _spoilerController.initializeParticles(spoilerMaskPath, widget.config);
  }

  @override
  void didUpdateWidget(covariant SpoilerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.textSelection != widget.config.textSelection) {
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
      builder: (context, _) {
        return GestureDetector(
          onTapDown: (details) {
            if (widget.config.enableGestureReveal) {
              // Toggle the spoiler's visibility state through the controller.
              _spoilerController.toggle(details.localPosition);
            }
          },
          child: SpoilerTextPainter(
            text: widget.text,
            textSelection: widget.config.textSelection,
            textAlign: widget.config.textAlign ?? TextAlign.start,
            style: widget.config.textStyle,
            maxLines: widget.config.maxLines,
            isEllipsis: widget.config.isEllipsis,
            onPaint: (canvas, size) {
              if (_spoilerController.isEnabled) {
                _spoilerController.drawParticles(canvas);
                canvas.clipPath(
                  _spoilerController.createSplashPathMaskClipper(size),
                );
              }
            },
            onInit: _setSpoilerRegions,
          ),
        );
      },
    );
  }
}
