import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

class SpoilerOverlayPage extends StatefulWidget {
  final bool fullPage;
  const SpoilerOverlayPage({
    super.key,
    this.fullPage = false,
  });

  @override
  State<SpoilerOverlayPage> createState() => _SpoilerOverlayPageState();
}

class _SpoilerOverlayPageState extends State<SpoilerOverlayPage> {
  static const _url =
      'https://img.freepik.com/premium-photo/drawing-female-superhero-female-character_1308175-151081.jpg?w=1800';

  bool divided = false;
  WidgetSpoilerConfig config(bool shaders) => WidgetSpoilerConfig.defaultConfig().copyWith(
        enableGestureReveal: true,
        particleConfig: const ParticleConfig(
          density: .1,
          speed: 0.25,
          color: Colors.white,
          maxParticleSize: 10.0,
          enableWaves: true,
          maxWaveRadius: 100.0,
          maxWaveCount: 5,
          shape: ParticleShape.star,
        ),
        shaderConfig: shaders ? ShaderConfig.particles() : null,
      );

  Widget imageWidget({bool shaders = false}) {
    return SpoilerOverlay(
      config: config(shaders),
      child: CachedNetworkImage(
        imageUrl: _url,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget fullWidget({bool shaders = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SpoilerOverlay(
        config: config(shaders),
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SpoilerOverlay')),
      backgroundColor: Colors.black,
      body: !widget.fullPage
          ? Center(
              child: SizedBox(
              width: 300,
              height: 300,
              child: imageWidget(shaders: true),
            ))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('Divided:'),
                      Switch(
                        value: divided,
                        onChanged: (value) {
                          setState(() {
                            divided = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: fullWidget(shaders: true),
                    ),
                    if (divided) Expanded(child: fullWidget()),
                  ],
                )),
              ],
            ),
    );
  }
}
