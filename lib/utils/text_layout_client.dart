import 'package:flutter/rendering.dart';

/// Minimal interface to access text layout boxes from either RenderEditable or TextPainter.
abstract class TextLayoutClient {
  Size get size;
  double get preferredLineHeight;
  List<TextBox> getBoxesForSelection(TextSelection selection);
}

/// [TextLayoutClient] adapter for [RenderEditable].
class RenderEditableLayoutClient implements TextLayoutClient {
  RenderEditableLayoutClient(this.render);

  final RenderEditable render;

  @override
  Size get size => render.size;

  @override
  double get preferredLineHeight => render.preferredLineHeight;

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) =>
      render.getBoxesForSelection(selection);
}

/// [TextLayoutClient] adapter for [RenderParagraph].
class RenderParagraphLayoutClient implements TextLayoutClient {
  RenderParagraphLayoutClient(this.render);

  final RenderParagraph render;

  @override
  Size get size => render.size;

  @override
  double get preferredLineHeight {
    final text = render.text.toPlainText();
    if (text.isEmpty) return 0;
    final boxes = render.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    if (boxes.isNotEmpty) {
      return boxes.first.toRect().height;
    }
    return render.size.height;
  }

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) =>
      render.getBoxesForSelection(selection);
}

/// [TextLayoutClient] adapter for [TextPainter].
class TextPainterLayoutClient implements TextLayoutClient {
  TextPainterLayoutClient(this.painter);

  final TextPainter painter;

  @override
  List<TextBox> getBoxesForSelection(TextSelection selection) =>
      painter.getBoxesForSelection(selection);

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
  final int rawStart =
      selection.start < selection.end ? selection.start : selection.end;
  final int rawEnd =
      selection.start > selection.end ? selection.start : selection.end;
  final int start = rawStart.clamp(0, text.length);
  final int end = rawEnd.clamp(0, text.length);
  if (start >= end) return (null, []);

  if (skipWhitespace) {
    final selectedText = text.substring(start, end);
    final matches = RegExp(r'\S+').allMatches(selectedText);
    if (matches.isEmpty) return (null, const <Rect>[]);

    final path = Path();
    final boxList = <Rect>[];
    for (final match in matches) {
      final runStart = start + match.start;
      final runEnd = start + match.end;
      final boxes = layout.getBoxesForSelection(
        TextSelection(baseOffset: runStart, extentOffset: runEnd),
      );
      for (final box in boxes) {
        final rect = box.toRect();
        boxList.add(rect);
        path.addRect(rect);
      }
    }

    return boxList.isEmpty ? (null, const <Rect>[]) : (path, boxList);
  }

  final boxes = layout.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  if (boxes.isEmpty) return (null, const <Rect>[]);

  final path = Path();
  final boxList = <Rect>[];
  for (final box in boxes) {
    final rect = box.toRect();
    boxList.add(rect);
    path.addRect(rect);
  }

  return (path, boxList);
}
