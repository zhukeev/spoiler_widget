import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/particle.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';

class TestSpoilerController extends SpoilerController {
  TestSpoilerController({required super.vsync});

  List<Particle> get debugParticles => particles;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SpoilerConfig buildConfig({required double updateInterval}) {
    return SpoilerConfig(
      isEnabled: true,
      enableGestureReveal: false,
      fadeConfig: const FadeConfig(padding: 1.0, edgeThickness: 1.0),
      particleConfig: ParticleConfig(
        density: 0.05,
        speed: 1.0,
        color: Colors.white,
        maxParticleSize: 2.0,
        updateInterval: updateInterval,
      ),
    );
  }

  testWidgets('particle updates throttle by updateInterval', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    final controller = TestSpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    controller.initializeParticles(
      Path()..addRect(const Rect.fromLTWH(0, 0, 100, 100)),
      buildConfig(updateInterval: 0.5),
    );

    expect(controller.debugParticles, isNotEmpty);
    final initial = controller.debugParticles.first;

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final afterShort = controller.debugParticles.first;
    expect(identical(afterShort, initial), isTrue);

    await tester.pump(const Duration(milliseconds: 400));

    final afterThreshold = controller.debugParticles.first;
    expect(identical(afterThreshold, initial), isFalse);
  });

  testWidgets('particle updates run every frame when interval is zero',
      (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    final controller = TestSpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    controller.initializeParticles(
      Path()..addRect(const Rect.fromLTWH(0, 0, 100, 100)),
      buildConfig(updateInterval: 0.0),
    );

    expect(controller.debugParticles, isNotEmpty);
    final initial = controller.debugParticles.first;

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));

    final afterTick = controller.debugParticles.first;
    expect(identical(afterTick, initial), isFalse);
  });
}
