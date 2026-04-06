// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/models/spoiler_drawing_strategy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugSpoilerLogger = debugPrint;
  });

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

  test('falls back to vector when atlas sprite creation fails', () {
    final previousBuilder = debugCircleImageBuilder;
    debugCircleImageBuilder = ({
      required double diameter,
      required Color color,
      Path? shapePath,
    }) {
      throw StateError('sprite creation failed');
    };
    addTearDown(() => debugCircleImageBuilder = previousBuilder);

    final controller = SpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    final config = SpoilerConfig(
      isEnabled: true,
      enableGestureReveal: false,
      enableFadeAnimation: false,
      particleConfig: const ParticleConfig(
        density: 0.2,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    final path = Path()..addRect(const Rect.fromLTWH(0, 0, 120, 40));
    expect(() => controller.initializeParticles(path, config), returnsNormally);

    expect(
      controller.debugParticleRenderBackend,
      ParticleRenderBackend.vector,
    );
    expect(controller.debugAtlasUnavailable, isTrue);
    expect(controller.isInitialized, isTrue);
  });

  test('falls back to vector when atlas draw fails during paint', () {
    final previousAtlasPainter = debugRawAtlasPainter;
    debugRawAtlasPainter = ({
      required Canvas canvas,
      required Image atlas,
      required Float32List transforms,
      required Float32List rects,
      Int32List? colors,
      BlendMode? blendMode,
      Rect? cullRect,
      required Paint paint,
    }) {
      throw StateError('atlas draw failed');
    } as RawAtlasPainter;
    addTearDown(() => debugRawAtlasPainter = previousAtlasPainter);

    final controller = SpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    final config = SpoilerConfig(
      isEnabled: true,
      enableGestureReveal: false,
      enableFadeAnimation: false,
      particleConfig: const ParticleConfig(
        density: 0.2,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    controller.initializeParticles(
      Path()..addRect(const Rect.fromLTWH(0, 0, 160, 40)),
      config,
    );

    var notifications = 0;
    controller.addListener(() => notifications++);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    expect(() => controller.drawParticles(canvas), returnsNormally);
    recorder.endRecording();

    expect(
      controller.debugParticleRenderBackend,
      ParticleRenderBackend.vector,
    );
    expect(controller.debugAtlasUnavailable, isTrue);
    expect(notifications, 0);
  });

  test('vector fallback keeps custom particle shapes drawable', () {
    final previousBuilder = debugCircleImageBuilder;
    debugCircleImageBuilder = ({
      required double diameter,
      required Color color,
      Path? shapePath,
    }) {
      throw StateError('sprite creation failed');
    };
    addTearDown(() => debugCircleImageBuilder = previousBuilder);

    final controller = SpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    final config = SpoilerConfig(
      isEnabled: true,
      enableGestureReveal: false,
      enableFadeAnimation: false,
      particleConfig: ParticleConfig(
        density: 0.2,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.5,
        shapePreset: ParticlePathPreset.star,
      ),
    );

    controller.initializeParticles(
      Path()..addRect(const Rect.fromLTWH(0, 0, 160, 40)),
      config,
    );

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    expect(() => controller.drawParticles(canvas), returnsNormally);
    recorder.endRecording();

    expect(
      controller.debugParticleRenderBackend,
      ParticleRenderBackend.vector,
    );
  });

  test('does not retry atlas after atlas is disabled for the controller', () {
    final previousBuilder = debugCircleImageBuilder;
    var buildAttempts = 0;
    debugCircleImageBuilder = ({
      required double diameter,
      required Color color,
      Path? shapePath,
    }) {
      buildAttempts++;
      throw StateError('sprite creation failed');
    };
    addTearDown(() => debugCircleImageBuilder = previousBuilder);

    final controller = SpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    final config = SpoilerConfig(
      isEnabled: true,
      enableGestureReveal: false,
      enableFadeAnimation: false,
      particleConfig: const ParticleConfig(
        density: 0.2,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    final path = Path()..addRect(const Rect.fromLTWH(0, 0, 120, 40));
    controller.initializeParticles(path, config);
    controller.initializeParticles(path, config);

    expect(buildAttempts, 1);
    expect(controller.debugParticleRenderBackend, ParticleRenderBackend.vector);
  });

  test('logs atlas fallback only once per controller transition', () {
    final previousBuilder = debugCircleImageBuilder;
    final logs = <String>[];
    var buildAttempts = 0;
    debugSpoilerLogger = logs.add;
    debugCircleImageBuilder = ({
      required double diameter,
      required Color color,
      Path? shapePath,
    }) {
      buildAttempts++;
      throw StateError('sprite creation failed');
    };
    addTearDown(() => debugCircleImageBuilder = previousBuilder);

    final controller = SpoilerController(vsync: const TestVSync());
    addTearDown(controller.dispose);

    final config = SpoilerConfig(
      isEnabled: true,
      enableGestureReveal: false,
      enableFadeAnimation: false,
      particleConfig: const ParticleConfig(
        density: 0.2,
        speed: 0.0,
        color: Colors.white,
        maxParticleSize: 1.0,
      ),
    );

    final path = Path()..addRect(const Rect.fromLTWH(0, 0, 120, 40));
    controller.initializeParticles(path, config);
    controller.initializeParticles(path, config);

    expect(buildAttempts, 1);
    expect(logs, hasLength(1));
    expect(logs.single, contains('Atlas rendering disabled at runtime'));
  });
}
