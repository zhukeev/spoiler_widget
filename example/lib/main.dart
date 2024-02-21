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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: RepaintBoundary(
            child: SpoilerTextWidget(
              enable: enable,
              maxParticleSize: 1.5,
              particleDensity: .4,
              speedOfParticles: 0.3,
              fadeRadius: 3,
              fadeAnimation: true,
              enableGesture: true,
              selection: const TextSelection(baseOffset: 0, extentOffset: 18),
              text: text,
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
