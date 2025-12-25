import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

class SpoilerTextWrapperPage extends StatelessWidget {
  const SpoilerTextWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    const text = 'This is a spoiler! Tap to reveal';
    return Scaffold(
      appBar: AppBar(title: const Text('SpoilerTextWrapper')),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SpoilerTextWrapper(
            config: TextSpoilerConfig(
              isEnabled: true,
              enableGestureReveal: true,
              // textSelection: const TextSelection(baseOffset: 0, extentOffset: 6),
              particleConfig: const ParticleConfig(
                maxParticleSize: 1,
                color: Colors.white,
                density: .5,
                speed: .2,
              ),
              fadeConfig: const FadeConfig(
                padding: 10,
                edgeThickness: 20,
              ),
              shaderConfig: ShaderConfig.particles(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  text,
                  style: TextStyle(fontSize: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(color: Colors.amber, width: 80, height: 80),
                    Container(color: Colors.blue, width: 80, height: 80),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  text,
                  style: TextStyle(fontSize: 32, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text.rich(
                  TextSpan(
                    text: 'This is a spoiler! Tap to reveal а.аа. с  \n asd',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
