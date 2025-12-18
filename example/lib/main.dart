import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final controller = TextEditingController(
    text: 'This is a spoiler! Tap to reveal',
  );
  bool enable = true;
  final text = 'This is a spoiler! Tap to reveal';

  final url =
      'https://img.freepik.com/premium-photo/drawing-female-superhero-female-character_1308175-151081.jpg?w=1800';

  SpoilerMask createStarPath(Size size, Offset offset) {
    Path path = Path();
    final cx = size.width / 2;
    final cy = size.height / 3;
    final radiusOuter = size.width;
    final radiusInner = radiusOuter / 2;
    const numPoints = 5;

    const angle = pi / (numPoints);
    path.moveTo(cx + radiusOuter * cos(0), cy + radiusOuter * sin(0));

    for (int i = 1; i <= numPoints * 2; i++) {
      final r = (i % 2 == 0) ? radiusOuter : radiusInner;
      final x = cx + r * cos(i * angle);
      final y = cy + r * sin(i * angle);
      path.lineTo(x, y);
    }
    path.close();

    final Matrix4 matrix = Matrix4.identity()
      ..translate(cx, cy, 0.0)
      ..rotateZ(1)
      ..translate(-cx, -cy, 0.0);
    return SpoilerMask(
      maskPath: path.transform(matrix.storage),
      maskOperation: PathOperation.intersect,
      offset: offset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              RepaintBoundary(
                child: SpoilerTextFieldWrapper(
                  config: TextSpoilerConfig(
                    particleDensity: .2,
                    enableGestureReveal: true,
                    enableFadeAnimation: true,
                    textSelection: const TextSelection(baseOffset: 3, extentOffset: 8),
                    textStyle: const TextStyle(fontSize: 50, color: Colors.white),
                  ),
                  builder: (context, contextMenuBuilder) => TextFormField(
                    controller: controller,
                    focusNode: FocusNode(),
                    contextMenuBuilder: contextMenuBuilder,
                    cursorColor: Colors.deepPurple,
                    maxLines: 3,
                  ),
                ),
              ),
              RepaintBoundary(
                child: SpoilerTextWrapper(
                  config: SpoilerConfig(
                    isEnabled: enable,
                    enableGestureReveal: true,
                    particleConfig: const ParticleConfig(
                      maxParticleSize: 1,
                      color: Colors.white,
                      density: .2,
                      speed: .2,
                    ),
                    fadeConfig: const FadeConfig(
                      padding: 10,
                      edgeThickness: 20,
                    ),
                    shaderConfig: ShaderConfig.particles(),
                    onSpoilerVisibilityChanged: (isVisible) {
                      debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
                    },
                  ),
                  child: Column(
                    children: [
                      Text(
                        text,
                        style: const TextStyle(fontSize: 50, color: Colors.white),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            color: Colors.amber,
                            width: 100,
                            height: 100,
                          ),
                          Container(
                            color: Colors.blue,
                            width: 100,
                            height: 100,
                          ),
                        ],
                      ),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 50, color: Colors.white),
                      ),
                      const Text.rich(
                        TextSpan(
                          text: 'This is a spoiler! Tap to reveal а.аа. с  \n asd',
                          style: TextStyle(fontSize: 20, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              RepaintBoundary(
                  child: SpoilerOverlay(
                config: WidgetSpoilerConfig.defaultConfig().copyWith(
                  enableGestureReveal: true,
                  enableFadeAnimation: true,
                  particleConfig: const ParticleConfig(
                    density: 0.1,
                    speed: 0.15,
                    color: Colors.white,
                    maxParticleSize: 1.0,
                    enableWaves: true,
                    maxWaveRadius: 100.0,
                    maxWaveCount: 5,
                  ),
                  shaderConfig: ShaderConfig.particles(),
                ),
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
