import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/widget_spoiler_config.dart';
import 'package:spoiler_widget/spoiler_overlay_widget.dart';

void main() {
  testWidgets('SpoilerOverlay disables via tap when enabled', (tester) async {
    final states = <bool>[];
    final config = WidgetSpoilerConfig(
      imageFilter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
      isEnabled: true,
      enableGestureReveal: true,
      enableFadeAnimation: false,
      onSpoilerVisibilityChanged: states.add,
      particleConfig: const ParticleConfig(
        density: 0.0,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 120,
            child: SpoilerOverlay(
              config: config,
              child: Container(
                key: const ValueKey('overlay-child'),
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    await tester.tap(find.byKey(const ValueKey('overlay-child')));
    await tester.pump();
    expect(states, isNotEmpty);
    expect(states.last, isFalse);
  });

  testWidgets('SpoilerOverlay ignores taps when gestures are disabled', (tester) async {
    final states = <bool>[];
    final config = WidgetSpoilerConfig(
      imageFilter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
      isEnabled: true,
      enableGestureReveal: false,
      enableFadeAnimation: false,
      onSpoilerVisibilityChanged: states.add,
      particleConfig: const ParticleConfig(
        density: 0.0,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 120,
            child: SpoilerOverlay(
              config: config,
              child: Container(
                key: const ValueKey('overlay-child'),
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    await tester.tap(find.byKey(const ValueKey('overlay-child')));
    await tester.pump();
    expect(states, isEmpty);
  });

  testWidgets('SpoilerOverlay enables via tap when disabled', (tester) async {
    final states = <bool>[];
    final config = WidgetSpoilerConfig(
      imageFilter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
      isEnabled: false,
      enableGestureReveal: true,
      enableFadeAnimation: false,
      onSpoilerVisibilityChanged: states.add,
      particleConfig: const ParticleConfig(
        density: 0.0,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 120,
            child: SpoilerOverlay(
              config: config,
              child: Container(
                key: const ValueKey('overlay-child'),
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    await tester.tap(find.byKey(const ValueKey('overlay-child')));
    await tester.pump();
    expect(states, isNotEmpty);
    expect(states.last, isTrue);
  });
}
