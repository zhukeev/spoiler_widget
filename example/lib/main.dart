import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/models/widget_spoiler.dart';
import 'package:spoiler_widget/spoiler_image_widget.dart';
import 'package:spoiler_widget/spoiler_text_widget.dart';
// import 'package:spoiler_widget/spoiler_widget.dart';

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

  final text = 'This is a spoiler! Tap to reveal.';

  final url =
      'https://img.freepik.com/premium-photo/drawing-female-superhero-female-character_1308175-151081.jpg?w=1800';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              child: SpoilerTextWidget(
                configuration: TextSpoilerConfiguration(
                  isEnabled: enable,
                  maxParticleSize: 1,
                  particleColor: Colors.white,
                  particleDensity: 5.5,
                  speedOfParticles: .2,
                  fadeRadius: 3,
                  fadeAnimation: true,
                  enableGesture: true,
                  selection: const TextSelection(baseOffset: 0, extentOffset: 22),
                  style: const TextStyle(
                    fontSize: 50,
                    color: Colors.white,
                  ),
                ),
                text: text,
              ),
            ),
            RepaintBoundary(
              child: SpoilerWidget(
                configuration: WidgetSpoilerConfiguration(
                  isEnabled: enable,
                  maxParticleSize: 1,
                  particleDensity: 25,
                  speedOfParticles: .2,
                  particleColor: Colors.white,
                  fadeRadius: 3,
                  fadeAnimation: true,
                  enableGesture: true,
                  imageFilter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
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
