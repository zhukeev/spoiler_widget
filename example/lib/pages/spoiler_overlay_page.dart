import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

class SpoilerOverlayPage extends StatelessWidget {
  final bool fullPage;
  const SpoilerOverlayPage({
    super.key,
    this.fullPage = false,
  });

  static const _url =
      'https://img.freepik.com/premium-photo/drawing-female-superhero-female-character_1308175-151081.jpg?w=1800';

  @override
  Widget build(BuildContext context) {
    final config = WidgetSpoilerConfig.defaultConfig().copyWith(
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
    );
    return Scaffold(
      appBar: AppBar(title: const Text('SpoilerOverlay')),
      backgroundColor: Colors.black,
      body: fullPage
          ? SpoilerOverlay(
              config: config,
              child: const SizedBox.expand(child: Placeholder()),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SpoilerOverlay(
                  config: config,
                  child: CachedNetworkImage(
                    imageUrl: _url,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
            ),
    );
  }
}
