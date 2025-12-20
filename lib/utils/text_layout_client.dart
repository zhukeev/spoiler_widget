import 'package:flutter/rendering.dart';

/// Minimal interface to access text layout boxes from either RenderEditable or TextPainter.
abstract class TextLayoutClient {
  Size get size;
  double get preferredLineHeight;
  List<TextBox> getBoxesForSelection(TextSelection selection);
}

class RenderEditableLayoutClient implements TextLayoutClient {
  RenderEditableLayoutClient(this.render);

  final RenderEditable render;

  @override
  Size get size => render.size;

  @override
  double get preferredLineHeight => render.preferredLineHeight;

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) => render.getBoxesForSelection(selection);
}

class TextPainterLayoutClient implements TextLayoutClient {
  TextPainterLayoutClient(this.painter);

  final TextPainter painter;

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) => painter.getBoxesForSelection(selection);

  @override
  double get preferredLineHeight => painter.preferredLineHeight;

  @override
  Size get size => painter.size;
}

/// Build a path for a selection using any [TextLayoutClient].
(Path?, List<Rect>) buildSelectionPath({
  required TextLayoutClient layout,
  required String text,
  required TextSelection selection,
  bool skipWhitespace = true,
}) {
  final int rawStart = selection.start < selection.end ? selection.start : selection.end;
  final int rawEnd = selection.start > selection.end ? selection.start : selection.end;
  final int start = rawStart.clamp(0, text.length);
  final int end = rawEnd.clamp(0, text.length);
  if (start >= end) return (null, []);

  final path = Path();
  final boxList = <Rect>[];
  bool hasContent = false;

  for (int i = start; i < end; i++) {
    final ch = text[i];
    if (skipWhitespace && ch.trim().isEmpty) continue;

    final boxes = layout.getBoxesForSelection(TextSelection(baseOffset: i, extentOffset: i + 1));
    for (final box in boxes) {
      boxList.add(box.toRect());
      path.addRect(box.toRect());
      hasContent = true;
    }
  }

  return hasContent ? (path, boxList) : (null, const <Rect>[]);
}
