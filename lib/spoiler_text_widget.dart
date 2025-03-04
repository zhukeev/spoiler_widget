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

  final TextSpoilerConfiguration config;
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
    if (oldWidget.config != widget.config) {
      _spoilerController.updateConfiguration(widget.config);
    } else if (oldWidget.text != widget.text || oldWidget.config.style != widget.config.style) {
      _spoilerController.disable();
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
            if (widget.config.enableGesture) {
              _spoilerController.toggle(details.localPosition);
            }
          },
          child: SpoilerTextPainter(
            text: widget.text,
            textSelection: widget.config.selection,
            style: widget.config.style,
            onPaint: (canvas, size) {
              _spoilerController.drawParticles(canvas);
              canvas.clipPath(_spoilerController.createSplashPathMaskClipper(size));
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
    this.style,
    this.textSelection,
    this.textAlign = TextAlign.start,
    Key? key,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final TextSelection? textSelection;
  final TextAlign textAlign;
  final ValueChanged<List<Rect>> onInit;
  final PaintCallback onPaint;

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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          textAlign: widget.textAlign,
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
