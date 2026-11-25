import 'package:flutter/rendering.dart';
import 'package:spoiler_widget/utils/text_layout_client.dart';

/// Bundles the path and rects that describe a spoiler selection.
class SpoilerGeometry {
  SpoilerGeometry({required this.path, required this.rects});

  /// Path representing the spoiler area.
  final Path path;

  /// Rectangles used to build the path.
  final List<Rect> rects;
}

/// Builds spoiler geometry for a given selection.
///
/// Uses any [TextLayoutClient] (RenderEditable/TextPainter) and skips whitespace
/// by default.
SpoilerGeometry? buildSpoilerGeometry({
  required TextLayoutClient layout,
  required String text,
  required TextSelection selection,
  bool skipWhitespace = true,
}) {
  final (path, rects) = buildSelectionPath(
    layout: layout,
    text: text,
    selection: selection,
    skipWhitespace: skipWhitespace,
  );
  if (path == null) return null;

  return SpoilerGeometry(path: path, rects: rects);
}
