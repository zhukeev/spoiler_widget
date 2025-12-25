import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/utils/spoiler_text_layout.dart.dart';

import 'canvas_callback_painter.dart';

/// Paints text with a spoiler overlay and reports text rects for masking.
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

  /// Full text content to render.
  final String text;

  /// Optional style used to measure and paint the text.
  final TextStyle? style;

  /// Optional selection range to mask.
  final TextSelection? textSelection;

  /// Alignment used when laying out the text.
  final TextAlign textAlign;

  /// Called with merged text rects after layout.
  final ValueChanged<List<Rect>> onInit;

  /// Called before text paint to draw particles/clip.
  final PaintCallback onPaint;

  /// Optional maximum number of lines for layout.
  final int? maxLines;

  /// Whether overflowing text should use an ellipsis.
  final bool? isEllipsis;

  @override
  State<SpoilerTextPainter> createState() => _SpoilerTextPainterState();
}

class _SpoilerTextPainterState extends State<SpoilerTextPainter> {
  final Set<Rect> _spoilerRegions = {};
  Size _previousSize = Size.zero;

  @override
  void didUpdateWidget(covariant SpoilerTextPainter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.style != widget.style ||
        oldWidget.text != widget.text ||
        oldWidget.textAlign != widget.textAlign ||
        oldWidget.textSelection != widget.textSelection ||
        oldWidget.maxLines != widget.maxLines ||
        oldWidget.isEllipsis != widget.isEllipsis) {
      _previousSize = Size.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;

    return LayoutBuilder(
      builder: (context, constraints) {
        final (geom, painter) = computeSpoilerTextLayout(
          text: widget.text,
          style: widget.style,
          textAlign: widget.textAlign,
          textDirection: direction,
          maxLines: widget.maxLines,
          isEllipsis: widget.isEllipsis ?? false,
          range: widget.textSelection == null
              ? null
              : TextRange(
                  start: widget.textSelection!.start,
                  end: widget.textSelection!.end,
                ),
          maxWidth: constraints.maxWidth,
        );

        final textSize = Size(
          painter.width,
          painter.height,
        );

        if (_previousSize != textSize) {
          _previousSize = textSize;
          _spoilerRegions
            ..clear()
            ..addAll(geom.rects);
          widget.onInit(_spoilerRegions.toList().mergeRects());
        }

        return CustomPaint(
          painter: CustomPainterCanvasCallback(
            onPaint: (canvas, size) {
              // 1) First draw spoiler / particles / clip.
              widget.onPaint(canvas, size);
              // 2) Then paint text.
              painter.paint(canvas, Offset.zero);
            },
          ),
          size: textSize,
        );
      },
    );
  }
}
