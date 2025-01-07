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

  final text = 'This is a spoiler! Tap to reveal.';

  final url =
      'https://img.freepik.com/premium-photo/drawing-female-superhero-female-character_1308175-151081.jpg?w=1800';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpoilerTextWidget(
              configuration: TextSpoilerConfiguration(
                isEnabled: enable,
                maxParticleSize: 1,
                particleDensity: 5.5,
                speedOfParticles: 0.2,
                fadeRadius: 3,
                fadeAnimation: true,
                enableGesture: true,
                selection: const TextSelection(baseOffset: 0, extentOffset: 18),
                style: const TextStyle(
                  fontSize: 50,
                  color: Colors.white,
                ),
              ),
              text: text,
            ),
            ClipRect(
              child: SpoilerWidget(
                configuration: WidgetSpoilerConfiguration(
                  isEnabled: enable,
                  maxParticleSize: 1,
                  particleDensity: 5,
                  speedOfParticles: 0.2,
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
