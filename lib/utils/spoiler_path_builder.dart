import 'package:flutter/rendering.dart';
import 'package:spoiler_widget/utils/path_signature.dart';
import 'package:spoiler_widget/utils/text_layout_client.dart';

class SpoilerGeometry {
  SpoilerGeometry({
    required this.path,
    required this.signature,
    required this.rects,
  });

  final Path path;
  final String signature;
  final List<Rect> rects;
}

/// Builds spoiler geometry (path + signature) for a given selection.
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

  return SpoilerGeometry(
    path: path,
    signature: pathSignature(path),
    rects: rects,
  );
}
