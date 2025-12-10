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
        body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                RepaintBoundary(
                  child: SpoilerTextWrapper(
                    config: SpoilerConfig(
                      isEnabled: enable,
                      maxParticleSize: 1,
                      particleColor: Colors.white,
                      particleDensity: .1,
                      particleSpeed: .2,
                      fadeRadius: 3,
                      enableFadeAnimation: true,
                      enableGestureReveal: true,
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 50, color: Colors.white),
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: SpoilerTextWrapper(
                    config: SpoilerConfig(
                      isEnabled: enable,
                      maxParticleSize: 1,
                      particleColor: Colors.white,
                      particleDensity: .1,
                      particleSpeed: .2,
                      fadeRadius: 3,
                      enableFadeAnimation: true,
                      enableGestureReveal: true,
                      customShaderPath: 'shaders/particles.frag',
                      onGetShaderUniforms: (rect, time, seed, config) {
                        return [
                          // 1. uResolution
                          rect.width, rect.height,
                          // 2. uTime
                          time,
                          // 3. uRect
                          rect.left, rect.top, rect.width, rect.height,
                          // 4. uSeed
                          seed,
                          // 5. uColor
                          config.particleColor.red / 255.0,
                          config.particleColor.green / 255.0,
                          config.particleColor.blue / 255.0,
                          // 6. uDensity
                          config.particleDensity,
                          // 7. uSize
                          config.maxParticleSize / 2,
                          // 8. uSpeed
                          config.particleSpeed,
                        ];
                      },
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
              ],
            ) ??
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  RepaintBoundary(
                    child: SpoilerTextFormField(
                      controller: controller,
                      focusNode: FocusNode(),
                      config: const TextSpoilerConfig(
                        particleDensity: .2,
                        enableGestureReveal: true,
                        enableFadeAnimation: true,
                        textSelection: TextSelection(baseOffset: 3, extentOffset: 8),
                        textStyle: TextStyle(fontSize: 50, color: Colors.white),
                      ),
                      cursorColor: Colors.deepPurple,
                      maxLines: 3,
                    ),
                  ),
                  RepaintBoundary(
                    child: SpoilerTextWrapper(
                      config: SpoilerConfig(
                        isEnabled: enable,
                        maxParticleSize: 1,
                        particleColor: Colors.white,
                        particleDensity: .1,
                        particleSpeed: .2,
                        fadeRadius: 3,
                        enableFadeAnimation: true,
                        enableGestureReveal: true,
                        customShaderPath: 'shaders/thermal.frag',
                        onGetShaderUniforms: (rect, time, seed, config) {
                          return [
                            // 1. uResolution
                            rect.width, rect.height,
                            // 2. uTime
                            time,
                            // 3. uRect
                            rect.left, rect.top, rect.width, rect.height,
                            // 4. uSeed
                            seed,
                            // 5. uColor
                            config.particleColor.red / 255.0,
                            config.particleColor.green / 255.0,
                            config.particleColor.blue / 255.0,
                            // 6. uDensity
                            config.particleDensity,
                            // 7. uSize
                            config.maxParticleSize,
                            // 8. uSpeed
                            config.particleSpeed,
                          ];
                        },
                        onSpoilerVisibilityChanged: (isVisible) {
                          debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
                        },
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
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
                  ),
                  RepaintBoundary(
                      child: SpoilerOverlay(
                    config: WidgetSpoilerConfig.defaultConfig().copyWith(
                      enableGestureReveal: true,
                      enableFadeAnimation: true,
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
