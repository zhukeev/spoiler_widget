import 'dart:ui' show ImageFilter, Path, Rect;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/models/widget_spoiler_config.dart';
import 'package:spoiler_widget/spoiler_overlay_widget.dart';
import 'package:spoiler_widget/spoiler_text_wrapper.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    binding.window.physicalSizeTestValue = const Size(360, 240);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  testWidgets('SpoilerTextWrapper hidden state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('wrapper-golden'),
          child: ColoredBox(
            color: const Color(0xFF202020),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SpoilerTextWrapper(
                  config: TextSpoilerConfig(
                    isEnabled: true,
                    enableGestureReveal: false,
                    particleConfig: const ParticleConfig(
                      density: 0.0,
                      speed: 0.0,
                      color: Colors.white,
                      maxParticleSize: 1.0,
                    ),
                    fadeConfig: const FadeConfig(
                      padding: 4.0,
                      edgeThickness: 2.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Secret line',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(width: 40, height: 40, child: ColoredBox(color: Colors.blue)),
                          SizedBox(width: 40, height: 40, child: ColoredBox(color: Colors.green)),
                          SizedBox(width: 40, height: 40, child: ColoredBox(color: Colors.orange)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Second line',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));

    await expectLater(
      find.byKey(const ValueKey('wrapper-golden')),
      matchesGoldenFile('goldens/spoiler_text_wrapper_hidden.png'),
    );
  });

  testWidgets('SpoilerOverlay disabled state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('overlay-golden'),
          child: ColoredBox(
            color: const Color(0xFF101010),
            child: Center(
              child: SizedBox(
                width: 220,
                height: 140,
                child: SpoilerOverlay(
                  config: WidgetSpoilerConfig(
                    imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                    isEnabled: false,
                    enableGestureReveal: false,
                    enableFadeAnimation: false,
                    particleConfig: const ParticleConfig(
                      density: 0.0,
                      speed: 0.0,
                      color: Colors.white,
                      maxParticleSize: 1.0,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3A7BD5),
                          Color(0xFF00D2FF),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));

    await expectLater(
      find.byKey(const ValueKey('overlay-golden')),
      matchesGoldenFile('goldens/spoiler_overlay_disabled.png'),
    );
  });

  testWidgets('SpoilerTextWrapper shader particles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('wrapper-particles-golden'),
          child: ColoredBox(
            color: const Color(0xFF202020),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SpoilerTextWrapper(
                  config: TextSpoilerConfig(
                    isEnabled: true,
                    enableGestureReveal: false,
                    enableFadeAnimation: false,
                    shaderConfig: _localParticleShader(),
                    particleConfig: const ParticleConfig(
                      density: 0.2,
                      speed: 0.0,
                      color: Colors.white,
                      maxParticleSize: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Secret line',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Another line',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await _allowShaderLoad(tester);

    await expectLater(
      find.byKey(const ValueKey('wrapper-particles-golden')),
      matchesGoldenFile('goldens/spoiler_text_wrapper_particles.png'),
    );
  });

  testWidgets('SpoilerOverlay shader particles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('overlay-particles-golden'),
          child: ColoredBox(
            color: const Color(0xFF101010),
            child: Center(
              child: SizedBox(
                width: 220,
                height: 140,
                child: SpoilerOverlay(
                  config: WidgetSpoilerConfig(
                    imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                    isEnabled: true,
                    enableGestureReveal: false,
                    enableFadeAnimation: false,
                    shaderConfig: _localParticleShader(),
                    particleConfig: const ParticleConfig(
                      density: 0.2,
                      speed: 0.0,
                      color: Colors.white,
                      maxParticleSize: 1.5,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3A7BD5),
                          Color(0xFF00D2FF),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await _allowShaderLoad(tester);

    await expectLater(
      find.byKey(const ValueKey('overlay-particles-golden')),
      matchesGoldenFile('goldens/spoiler_overlay_particles.png'),
    );
  });

  testWidgets('SpoilerTextWrapper masked shader', (tester) async {
    final maskPath = Path()..addRect(const Rect.fromLTWH(0, 0, 120, 40));

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('wrapper-mask-golden'),
          child: ColoredBox(
            color: const Color(0xFF202020),
            child: Center(
              child: SpoilerTextWrapper(
                config: TextSpoilerConfig(
                  isEnabled: true,
                  enableGestureReveal: false,
                  enableFadeAnimation: false,
                  shaderConfig: _localParticleShader(),
                  maskConfig: SpoilerMask(
                    maskPath: maskPath,
                    maskOperation: PathOperation.intersect,
                  ),
                  particleConfig: const ParticleConfig(
                    density: 0.2,
                    speed: 0.0,
                    color: Colors.white,
                    maxParticleSize: 1.5,
                  ),
                ),
                child: const SizedBox(
                  width: 240,
                  height: 40,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Masked spoiler text',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await _allowShaderLoad(tester);

    await expectLater(
      find.byKey(const ValueKey('wrapper-mask-golden')),
      matchesGoldenFile('goldens/spoiler_text_wrapper_masked.png'),
    );
  });

  testWidgets('SpoilerOverlay shader waves', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('overlay-waves-golden'),
          child: ColoredBox(
            color: const Color(0xFF101010),
            child: Center(
              child: SizedBox(
                width: 220,
                height: 140,
                child: SpoilerOverlay(
                  config: WidgetSpoilerConfig(
                    imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                    isEnabled: true,
                    enableGestureReveal: false,
                    enableFadeAnimation: false,
                    shaderConfig: _localParticleShader(),
                    particleConfig: const ParticleConfig(
                      density: 0.22,
                      speed: 0.25,
                      color: Colors.white,
                      maxParticleSize: 1.5,
                      enableWaves: true,
                      maxWaveRadius: 80.0,
                      maxWaveCount: 3,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF7F7FD5),
                          Color(0xFF86A8E7),
                          Color(0xFF91EAE4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await _allowShaderLoad(tester);
    await _advanceShaderFrames(tester, frames: 6);

    await expectLater(
      find.byKey(const ValueKey('overlay-waves-golden')),
      matchesGoldenFile('goldens/spoiler_overlay_waves.png'),
    );
  });
}

Future<void> _allowShaderLoad(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  await tester.binding.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> _advanceShaderFrames(WidgetTester tester, {int frames = 4}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

ShaderConfig _localParticleShader() {
  final base = ShaderConfig.particles();
  return ShaderConfig(
    customShaderPath: 'shaders/particles.frag',
    onGetShaderUniforms: base.onGetShaderUniforms,
  );
}
