import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

class SpoilerTextPage extends StatelessWidget {
  const SpoilerTextPage({super.key});

  @override
  Widget build(BuildContext context) {
    const text = 'This is a spoiler! Tap to reveal';
    return Scaffold(
      appBar: AppBar(title: const Text('SpoilerText')),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SpoilerText(
            config: TextSpoilerConfig(
              isEnabled: true,
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
            ),
            text: text,
          ),
        ),
      ),
    );
  }
}
