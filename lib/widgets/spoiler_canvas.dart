import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// Painting context that captures text bounding rects while delegating
/// normal painting to Flutter's pipeline.
class SpoilerPaintingContext extends PaintingContext {
  SpoilerPaintingContext({
    required ContainerLayer layer,
    required Rect estimatedBounds,
    required this.calculateRects,
  }) : super(layer, estimatedBounds);

  final bool calculateRects;
  final List<Rect> spoilerRects = [];
  String? currentText;

  @override
  ui.Canvas get canvas => SpoilerCanvas(super.canvas, this);

  @override
  void paintChild(RenderObject child, Offset offset) {
    if (calculateRects) {
      if (child is RenderParagraph) {
        currentText = child.text.toPlainText();
      } else if (child is RenderEditable) {
        currentText = child.plainText;
        if (currentText != null && currentText!.isNotEmpty) {
          final boxes = child.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: currentText!.length),
          );
          final paintOffset = editablePaintOffset(child);
          for (final b in boxes) {
            spoilerRects.add(
              normalizeEditableRect(
                b.toRect().shift(offset + paintOffset),
                child,
              ),
            );
          }
        }
      }
    }
    super.paintChild(child, offset);
    currentText = null;
  }

  @override
  PaintingContext createChildContext(
    ContainerLayer childLayer,
    ui.Rect bounds,
  ) {
    return _ChildSpoilerPaintingContext(
      layer: childLayer,
      estimatedBounds: bounds,
      rootRects: spoilerRects,
      calculateRects: calculateRects,
    );
  }
}

/// Child context that appends rects into the root's collection so nested
/// children contribute to a single list.
class _ChildSpoilerPaintingContext extends SpoilerPaintingContext {
  _ChildSpoilerPaintingContext({
    required super.layer,
    required super.estimatedBounds,
    required this.rootRects,
    required super.calculateRects,
  });

  final List<Rect> rootRects;

  @override
  List<Rect> get spoilerRects => rootRects;
}

/// Compensates for scroll offsets when mapping editable text boxes into
/// spoiler-local coordinates.
Offset editablePaintOffset(RenderEditable editable) {
  // Use a stable reference: first glyph box vs caret at offset 0.
  try {
    final text = editable.plainText;
    if (text.isNotEmpty) {
      final caret = editable.getLocalRectForCaret(
        const TextPosition(offset: 0),
      );
      final boxes = editable.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      );
      if (boxes.isNotEmpty) {
        return caret.topLeft - boxes.first.toRect().topLeft;
      }
    }
  } catch (_) {
    // ignore and fall back
  }

  // Fallback to scroll-based approximation if caret metrics aren't available.
  final pixels = editable.offset.pixels;
  if (pixels == 0) return Offset.zero;
  final isSingleLine = editable.maxLines == 1;
  if (isSingleLine) {
    return editable.textDirection == TextDirection.rtl
        ? Offset(pixels, 0)
        : Offset(-pixels, 0);
  }
  return Offset(0, -pixels);
}

Rect normalizeEditableRect(Rect rect, RenderEditable editable) {
  final minHeight = editable.preferredLineHeight;
  const double leftPadding =
      2.0; // cover leading-side clipping (e.g., descenders at start)
  return Rect.fromLTRB(
    rect.left - leftPadding,
    rect.top,
    rect.right,
    rect.top + minHeight,
  );
}

/// Canvas wrapper that collects paragraph word bounds while forwarding all
/// drawing to the underlying canvas.
class SpoilerCanvas implements Canvas {
  SpoilerCanvas(this.parent, this.context);

  final Canvas parent;
  final SpoilerPaintingContext context;

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    if (context.calculateRects) {
      var currentOffset = 0;
      while (true) {
        final range = paragraph.getWordBoundary(
          ui.TextPosition(offset: currentOffset),
        );
        if (range.start == range.end) break;

        final fullText = context.currentText ?? '';

        if (fullText.length >= range.end) {
          final wordText = fullText.substring(range.start, range.end);
          final trimmed = wordText.trim();

          if (trimmed.isNotEmpty) {
            final trimStart = wordText.indexOf(trimmed);
            final start = range.start + trimStart;
            final end = start + trimmed.length;

            final boxes = paragraph.getBoxesForRange(start, end);
            for (final box in boxes) {
              final rect = box.toRect().shift(offset);
              context.spoilerRects.add(rect);
            }
          }
        }

        if (range.end <= currentOffset) break;
        currentOffset = range.end;
      }
    }

    parent.drawParagraph(paragraph, offset);
  }

  @override
  void save() => parent.save();
  @override
  void saveLayer(Rect? bounds, Paint paint) => parent.saveLayer(bounds, paint);
  @override
  void restore() => parent.restore();
  @override
  void restoreToCount(int count) => parent.restoreToCount(count);
  @override
  int getSaveCount() => parent.getSaveCount();
  @override
  void translate(double dx, double dy) => parent.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => parent.scale(sx, sy);
  @override
  void rotate(double radians) => parent.rotate(radians);
  @override
  void skew(double sx, double sy) => parent.skew(sx, sy);
  @override
  void transform(Float64List matrix4) => parent.transform(matrix4);
  @override
  Float64List getTransform() => parent.getTransform();
  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) => parent.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      parent.clipRRect(rrect, doAntiAlias: doAntiAlias);
  @override
  void clipPath(Path path, {bool doAntiAlias = true}) =>
      parent.clipPath(path, doAntiAlias: doAntiAlias);
  @override
  Rect getLocalClipBounds() => parent.getLocalClipBounds();
  @override
  Rect getDestinationClipBounds() => parent.getDestinationClipBounds();
  @override
  void drawColor(Color color, BlendMode blendMode) =>
      parent.drawColor(color, blendMode);
  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      parent.drawLine(p1, p2, paint);
  @override
  void drawPaint(Paint paint) => parent.drawPaint(paint);
  @override
  void drawRect(Rect rect, Paint paint) => parent.drawRect(rect, paint);
  @override
  void drawRRect(RRect rrect, Paint paint) => parent.drawRRect(rrect, paint);
  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) =>
      parent.drawDRRect(outer, inner, paint);
  @override
  void drawOval(Rect rect, Paint paint) => parent.drawOval(rect, paint);
  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      parent.drawCircle(c, radius, paint);
  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) => parent.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  @override
  void drawPath(Path path, Paint paint) => parent.drawPath(path, paint);
  @override
  void drawImage(ui.Image image, Offset p, Paint paint) =>
      parent.drawImage(image, p, paint);
  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) =>
      parent.drawImageRect(image, src, dst, paint);
  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) =>
      parent.drawImageNine(image, center, dst, paint);
  @override
  void drawPicture(ui.Picture picture) => parent.drawPicture(picture);
  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) =>
      parent.drawPoints(pointMode, points, paint);
  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) =>
      parent.drawVertices(vertices, blendMode, paint);
  @override
  void drawAtlas(
    ui.Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) => parent.drawAtlas(
    atlas,
    transforms,
    rects,
    colors,
    blendMode,
    cullRect,
    paint,
  );
  @override
  void drawRawAtlas(
    ui.Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) => parent.drawRawAtlas(
    atlas,
    rstTransforms,
    rects,
    colors,
    blendMode,
    cullRect,
    paint,
  );
  @override
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  ) => parent.drawShadow(path, color, elevation, transparentOccluder);
  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) =>
      parent.drawRawPoints(pointMode, points, paint);

  @override
  void clipRSuperellipse(
    ui.RSuperellipse rsuperellipse, {
    bool doAntiAlias = true,
  }) => parent.clipRSuperellipse(rsuperellipse, doAntiAlias: doAntiAlias);

  @override
  void drawRSuperellipse(ui.RSuperellipse rsuperellipse, ui.Paint paint) =>
      parent.drawRSuperellipse(rsuperellipse, paint);
}
