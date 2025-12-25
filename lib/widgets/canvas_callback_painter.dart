import 'package:flutter/rendering.dart';

typedef PaintCallback = void Function(Canvas canvas, Size size);

/// Custom painter that calls [onPaint] callback on paint.
///
/// [repaint] is used to trigger repaints when needed.
class CustomPainterCanvasCallback extends CustomPainter {
  final PaintCallback onPaint;

  const CustomPainterCanvasCallback({required this.onPaint, super.repaint});

  @override
  void paint(Canvas canvas, Size size) => onPaint.call(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate != this;
}
