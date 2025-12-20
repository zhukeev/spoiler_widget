import 'package:flutter/material.dart';

import 'spoiler_path_builder.dart';
import 'text_layout_client.dart';

/// Compute layout and word regions for spoiler text.
///
/// If [range] == null:
///   - walk the whole text and collect non-whitespace "words".
/// If [range] != null:
///   - collect selection boxes only for that range.
(SpoilerGeometry geometry, TextPainter painter) computeSpoilerTextLayout({
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

  final selection = range == null
      ? TextSelection(baseOffset: 0, extentOffset: text.length)
      : TextSelection(
          baseOffset: range.start.clamp(0, text.length),
          extentOffset: range.end.clamp(0, text.length),
        );

  final geom = buildSpoilerGeometry(
    layout: TextPainterLayoutClient(painter),
    text: text,
    selection: selection,
    skipWhitespace: true,
  );

  return (geom!, painter);
}
