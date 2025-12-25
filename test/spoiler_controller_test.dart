// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toggle respects path containment and notifies listeners', () {
    final controller = SpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    final calls = <bool>[];
    final config = SpoilerConfig(
      isEnabled: false,
      enableGestureReveal: true,
      enableFadeAnimation: false,
      onSpoilerVisibilityChanged: calls.add,
      particleConfig: const ParticleConfig(
        density: 0.0,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    final path = Path()..addRect(const Rect.fromLTWH(0, 0, 100, 20));
    controller.initializeParticles(path, config);

    expect(controller.toggle(const Offset(200, 200)), isFalse);
    expect(controller.isEnabled, isFalse);
    expect(calls, isEmpty);

    expect(controller.toggle(const Offset(10, 10)), isTrue);
    expect(controller.isEnabled, isTrue);
    expect(calls.last, isTrue);

    expect(controller.toggle(const Offset(10, 10)), isTrue);
    expect(controller.isEnabled, isFalse);
    expect(calls.last, isFalse);
  });

  test('disable stops immediately when fade is disabled', () {
    final controller = SpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    final config = SpoilerConfig(
      isEnabled: true,
      enableGestureReveal: true,
      enableFadeAnimation: false,
      particleConfig: const ParticleConfig(
        density: 0.0,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    final path = Path()..addRect(const Rect.fromLTWH(0, 0, 50, 20));
    controller.initializeParticles(path, config);

    expect(controller.isEnabled, isTrue);
    controller.disable();
    expect(controller.isEnabled, isFalse);
  });
}
