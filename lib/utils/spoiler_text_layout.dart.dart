import 'package:flutter/material.dart';

/// Result of laying out spoiler text:
///  - [painter]: ready-to-paint TextPainter
///  - [wordRects]: rects for either all words or the given range
///  - [wordPath]: union of all [wordRects] as a Path
@immutable
class SpoilerTextLayoutResult {
  const SpoilerTextLayoutResult({
    required this.painter,
    required this.wordRects,
    required this.wordPath,
  });

  final TextPainter painter;
  final Set<Rect> wordRects;
  final Path wordPath;
}

/// Compute layout and word regions for spoiler text.
///
/// If [range] == null:
///   - walk the whole text and collect non-whitespace "words".
/// If [range] != null:
///   - collect selection boxes only for that range.
SpoilerTextLayoutResult computeSpoilerTextLayout({
  required String text,
  required TextStyle? style,
  required TextAlign textAlign,
  required TextDirection textDirection,
  int? maxLines,
  TextScaler textScaler = TextScaler.noScaling,
  TextHeightBehavior? textHeightBehavior,
  Locale? locale,
  StrutStyle? strutStyle,
  bool isEllipsis = false,
  TextRange? range,
  required double maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    textAlign: textAlign,
    maxLines: maxLines,
    ellipsis: isEllipsis ? '…' : null,
    textScaler: textScaler,
    textHeightBehavior: textHeightBehavior,
    locale: locale,
    strutStyle: strutStyle,
  );

  painter.layout(maxWidth: maxWidth);

  final rects = <Rect>{};
  final path = Path();

  if (text.isEmpty) {
    return SpoilerTextLayoutResult(
      painter: painter,
      wordRects: rects,
      wordPath: path,
    );
  }

  if (range != null) {
    final clamped = TextRange(
      start: range.start.clamp(0, text.length),
      end: range.end.clamp(0, text.length),
    );

    if (clamped.isValid && !clamped.isCollapsed) {
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: clamped.start, extentOffset: clamped.end),
      );
      for (final box in boxes) {
        final rect = box.toRect();
        rects.add(rect);
        path.addRect(rect);
      }
    }

    return SpoilerTextLayoutResult(
      painter: painter,
      wordRects: rects,
      wordPath: path,
    );
  }

  // No explicit range → walk all word boundaries.
  int index = 0;
  final end = text.length;

  while (index < end) {
    // Skip whitespace.
    while (index < end && text[index].trim().isEmpty) {
      index++;
    }
    if (index >= end) break;

    final wordStart = index;

    // Consume non-whitespace characters.
    while (index < end && text[index].trim().isNotEmpty) {
      index++;
    }
    final wordEnd = index;

    final selection = TextSelection(
      baseOffset: wordStart,
      extentOffset: wordEnd,
    );
    final boxes = painter.getBoxesForSelection(selection);

    if (boxes.isNotEmpty) {
      final rect = boxes.first.toRect();
      rects.add(rect);
      path.addRect(rect);
    }
  }

  return SpoilerTextLayoutResult(
    painter: painter,
    wordRects: rects,
    wordPath: path,
  );
}
