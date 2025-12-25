import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/extension/path_x.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/utils/path_signature.dart';
import 'package:spoiler_widget/utils/text_layout_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ParticleConfig areaFactor uses preset value', () {
    final config = ParticleConfig(
      density: 0.1,
      speed: 0.2,
      color: Colors.white,
      maxParticleSize: 1.0,
      shapePreset: ParticlePathPreset.star,
    );

    expect(config.areaFactor,
        closeTo(ParticlePathPreset.star.areaFactor!, 0.0001));
  });

  test('ParticleConfig areaFactor computes for custom path', () {
    final square = Path()..addRect(const Rect.fromLTWH(-1, -1, 2, 2));
    final config = ParticleConfig(
      density: 0.1,
      speed: 0.2,
      color: Colors.white,
      maxParticleSize: 1.0,
      shapePreset: ParticlePathPreset.custom(square),
    );

    expect(config.areaFactor, closeTo(4 / math.pi, 0.1));
  });

  test('pathSignature changes when path geometry changes', () {
    final path = Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10));
    final first = pathSignature(path);

    path.addRect(const Rect.fromLTWH(20, 0, 5, 5));
    final second = pathSignature(path);

    expect(first, isNot(second));
  });

  test('buildSelectionPath skips whitespace-only selection', () {
    const text = 'hi  there';
    final painter = TextPainter(
      text: const TextSpan(text: text, style: TextStyle()),
      textDirection: TextDirection.ltr,
    )..layout();

    final (path, rects) = buildSelectionPath(
      layout: TextPainterLayoutClient(painter),
      text: text,
      selection: const TextSelection(baseOffset: 2, extentOffset: 4),
      skipWhitespace: true,
    );

    expect(path, isNull);
    expect(rects, isEmpty);
  });

  test('buildSelectionPath clamps selection to text length', () {
    const text = 'hello';
    final painter = TextPainter(
      text: const TextSpan(text: text, style: TextStyle()),
      textDirection: TextDirection.ltr,
    )..layout();

    final (path, rects) = buildSelectionPath(
      layout: TextPainterLayoutClient(painter),
      text: text,
      selection: const TextSelection(baseOffset: -1, extentOffset: 100),
      skipWhitespace: true,
    );

    expect(path, isNotNull);
    expect(rects, isNotEmpty);
  });

  test('buildSelectionPath handles reversed selections', () {
    const text = 'hello';
    final painter = TextPainter(
      text: const TextSpan(text: text, style: TextStyle()),
      textDirection: TextDirection.ltr,
    )..layout();

    final (_, forwardRects) = buildSelectionPath(
      layout: TextPainterLayoutClient(painter),
      text: text,
      selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      skipWhitespace: true,
    );
    final (_, reversedRects) = buildSelectionPath(
      layout: TextPainterLayoutClient(painter),
      text: text,
      selection: const TextSelection(baseOffset: 5, extentOffset: 0),
      skipWhitespace: true,
    );

    expect(reversedRects, isNotEmpty);
    expect(reversedRects.length, forwardRects.length);
  });

  test('buildSelectionPath returns null for empty selection', () {
    const text = 'hello';
    final painter = TextPainter(
      text: const TextSpan(text: text, style: TextStyle()),
      textDirection: TextDirection.ltr,
    )..layout();

    final (path, rects) = buildSelectionPath(
      layout: TextPainterLayoutClient(painter),
      text: text,
      selection: const TextSelection.collapsed(offset: 2),
      skipWhitespace: true,
    );

    expect(path, isNull);
    expect(rects, isEmpty);
  });

  test('RectX mergeRects merges adjacent rectangles', () {
    final rects = [
      const Rect.fromLTWH(0, 0, 5, 5),
      const Rect.fromLTWH(5, 0, 5, 5),
      const Rect.fromLTWH(20, 0, 5, 5),
    ];

    final merged = rects.mergeRects();

    expect(merged.length, 2);
    expect(merged.first, const Rect.fromLTWH(0, 0, 10, 5));
    expect(merged.last, const Rect.fromLTWH(20, 0, 5, 5));
  });

  test('RectX getBounds returns union bounds', () {
    final rects = [
      const Rect.fromLTWH(0, 0, 5, 5),
      const Rect.fromLTWH(10, 5, 5, 5),
    ];

    final bounds = rects.getBounds();

    expect(bounds, const Rect.fromLTRB(0, 0, 15, 10));
  });

  test('PathX getRandomPoint returns a point inside path', () {
    final path = Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10));
    final point = path.getRandomPoint();

    expect(path.contains(point), isTrue);
  });
}
