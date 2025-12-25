import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/models/widget_spoiler_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SpoilerConfig legacy fields map to particle and fade configs', () {
    final config = SpoilerConfig(
      particleDensity: 0.25,
      particleSpeed: 0.4,
      particleColor: Colors.red,
      maxParticleSize: 2.0,
      enableFadeAnimation: true,
      fadeRadius: 8.0,
      fadeEdgeThickness: 5.0,
      isEnabled: true,
      enableGestureReveal: false,
    );

    expect(config.particleConfig.density, 0.25);
    expect(config.particleConfig.speed, 0.4);
    expect(config.particleConfig.color, Colors.red);
    expect(config.particleConfig.maxParticleSize, 2.0);
    expect(config.fadeConfig, isNotNull);
    expect(config.fadeConfig!.padding, 8.0);
    expect(config.fadeConfig!.edgeThickness, 5.0);
  });

  test('SpoilerConfig copyWith legacy overrides keep other values', () {
    final config = SpoilerConfig(
      particleDensity: 0.25,
      particleSpeed: 0.4,
      particleColor: Colors.red,
      maxParticleSize: 2.0,
      enableFadeAnimation: true,
      fadeRadius: 8.0,
      fadeEdgeThickness: 5.0,
      isEnabled: true,
      enableGestureReveal: false,
    );

    final next = config.copyWith(particleDensity: 0.5);

    expect(next.particleConfig.density, 0.5);
    expect(next.particleConfig.speed, 0.4);
    expect(next.particleConfig.color, Colors.red);
    expect(next.particleConfig.maxParticleSize, 2.0);
  });

  test('SpoilerConfig disables fade when enableFadeAnimation is false', () {
    final config = SpoilerConfig(
      enableFadeAnimation: false,
      isEnabled: true,
      enableGestureReveal: true,
    );

    expect(config.fadeConfig, isNull);
  });

  test('TextSpoilerConfig copyWith updates text fields', () {
    const baseSelection = TextSelection(baseOffset: 0, extentOffset: 4);
    const nextSelection = TextSelection(baseOffset: 1, extentOffset: 3);
    final base = TextSpoilerConfig(
      textStyle: const TextStyle(color: Colors.blue),
      textSelection: baseSelection,
      textAlign: TextAlign.left,
      maxLines: 2,
      isEllipsis: true,
      isEnabled: true,
      enableGestureReveal: true,
      particleConfig: const ParticleConfig(
        density: 0.1,
        speed: 0.2,
        color: Colors.green,
        maxParticleSize: 1.0,
      ),
      fadeConfig: const FadeConfig(
        padding: 2.0,
        edgeThickness: 3.0,
      ),
    );

    final next = base.copyWith(
      textAlign: TextAlign.center,
      textSelection: nextSelection,
    );

    expect(next.textAlign, TextAlign.center);
    expect(next.textSelection, nextSelection);
    expect(next.textStyle, base.textStyle);
    expect(next.particleConfig, base.particleConfig);
    expect(next.fadeConfig, base.fadeConfig);
  });

  test('WidgetSpoilerConfig copyWith updates image filter and wave count', () {
    final config = WidgetSpoilerConfig(
      imageFilter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 2.0),
      maxActiveWaves: 4,
    );

    final next = config.copyWith(
      imageFilter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 4.0),
      maxActiveWaves: 2,
    );

    expect(next.maxActiveWaves, 2);
    expect(identical(next.imageFilter, config.imageFilter), isFalse);
  });
}
