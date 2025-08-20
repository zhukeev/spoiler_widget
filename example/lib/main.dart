import 'dart:math';
import 'dart:ui';

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
      ..translate(cx, cy)
      ..rotateZ(1)
      ..translate(-cx, -cy);
    return SpoilerMask(
      maskPath: path.transform(matrix.storage),
      maskOperation: PathOperation.intersect,
      offset: offset,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // showPerformanceOverlay: true,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              child: SpoilerText(
                config: TextSpoilerConfig(
                  isEnabled: enable,
                  maxParticleSize: 1,
                  particleColor: Colors.white,
                  particleDensity: .1,
                  particleSpeed: .2,
                  fadeRadius: 3,
                  enableFadeAnimation: true,
                  enableGestureReveal: true,
                  textStyle: const TextStyle(
                    fontSize: 50,
                    color: Colors.white,
                  ),
                  maskConfig: createStarPath(const Size.square(80), const Offset(230, 30)),
                  maxLines: 1,
                  isEllipsis: true
                ),
                text: text,
              ),
            ),
            RepaintBoundary(
              child: SpoilerOverlay(
                config: WidgetSpoilerConfig(
                  isEnabled: enable,
                  maxParticleSize: 1,
                  particleDensity: .1,
                  particleSpeed: .4,
                  particleColor: Colors.white,
                  fadeRadius: 3,
                  enableFadeAnimation: true,
                  enableGestureReveal: true,
                  imageFilter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
                  maskConfig: createStarPath(const Size.square(80), const Offset(200, 90)),
                ),
                child: CachedNetworkImage(imageUrl: url),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
