import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/utils/spoiler_text_layout.dart.dart';

import 'canvas_callback_painter.dart';

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
