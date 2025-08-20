import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/widgets/canvas_callback_painter.dart';

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

class _SpoilerTextState extends State<SpoilerText> with TickerProviderStateMixin {
  late final SpoilerController _spoilerController = SpoilerController(vsync: this);

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
                canvas.clipPath(_spoilerController.createSplashPathMaskClipper(size));
              }
            },
            onInit: _setSpoilerRegions,
          ),
        );
      },
    );
  }
}

@immutable
class SpoilerTextPainter extends StatefulWidget {
  const SpoilerTextPainter({
    required this.text,
    required this.onInit,
    required this.onPaint,
    required this.textAlign,
    this.style,
    this.textSelection,
    this.maxLines,
    this.isEllipsis,
    Key? key,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final TextSelection? textSelection;
  final TextAlign textAlign;
  final ValueChanged<List<Rect>> onInit;
  final PaintCallback onPaint;
  final int? maxLines;
  final bool? isEllipsis;

  @override
  State<SpoilerTextPainter> createState() => _SpoilerTextPainterState();
}

class _SpoilerTextPainterState extends State<SpoilerTextPainter> {
  final Set<Rect> _spoilerRegions = {};
  Size _previousSize = Size.zero;

  void _extractTextBoundaries(TextPainter textPainter, int offset) {
    if (widget.textSelection != null) {
      final selectedBoxes = textPainter.getBoxesForSelection(widget.textSelection!);
      for (final box in selectedBoxes) {
        _spoilerRegions.add(box.toRect());
      }
      return;
    }

    final wordRange = textPainter.getWordBoundary(TextPosition(offset: offset));
    if (wordRange.isCollapsed) return;

    final substring = widget.text.substring(wordRange.start, wordRange.end);
    if (substring.trim().isEmpty) {
      _extractTextBoundaries(textPainter, wordRange.end);
      return;
    }

    final wordBoxes = textPainter.getBoxesForSelection(
      TextSelection(baseOffset: wordRange.start, extentOffset: wordRange.end),
    );

    if (wordBoxes.isNotEmpty) {
      _spoilerRegions.add(wordBoxes.first.toRect());
    }
    _extractTextBoundaries(textPainter, wordRange.end);
  }

  @override
  void didUpdateWidget(covariant SpoilerTextPainter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.style != widget.style ||
        oldWidget.text != widget.text ||
        oldWidget.textAlign != widget.textAlign ||
        oldWidget.textSelection != widget.textSelection) {
      _previousSize = Size.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          ellipsis: widget.isEllipsis == true ? '…' : null,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);
        final textSize = Size(textPainter.width, textPainter.height);

        if (_previousSize != textSize) {
          _spoilerRegions.clear();
          _extractTextBoundaries(textPainter, 0);
          _previousSize = textSize;
          widget.onInit(_spoilerRegions.toList().mergeRects());
        }

        return CustomPaint(
          painter: CustomPainterCanvasCallback(
            onPaint: (canvas, size) {
              widget.onPaint(canvas, size);
              textPainter.paint(canvas, Offset.zero);
            },
          ),
          size: textSize,
        );
      },
    );
  }
}
