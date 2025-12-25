import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/spoiler_text_wrapper.dart';

void main() {
  testWidgets('SpoilerTextWrapper toggles via tap when gestures enabled',
      (tester) async {
    bool? lastVisibility;
    final config = TextSpoilerConfig(
      isEnabled: true,
      enableGestureReveal: true,
      onSpoilerVisibilityChanged: (value) => lastVisibility = value,
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
          body: Center(
            child: SpoilerTextWrapper(
              config: config,
              child: const Text('secret'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('secret'));
    await tester.pump();

    expect(lastVisibility, isFalse);
  });

  testWidgets('SpoilerTextWrapper ignores tap when gestures disabled',
      (tester) async {
    bool? lastVisibility;
    final config = TextSpoilerConfig(
      isEnabled: true,
      enableGestureReveal: false,
      onSpoilerVisibilityChanged: (value) => lastVisibility = value,
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
          body: Center(
            child: SpoilerTextWrapper(
              config: config,
              child: const Text('secret'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('secret'));
    await tester.pump();

    expect(lastVisibility, isNull);
  });
}
