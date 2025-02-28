# Spoiler Animation for Flutter

![Pub Likes](https://img.shields.io/pub/likes/spoiler_widget)
![Pub Points](https://img.shields.io/pub/points/spoiler_widget)
[![Pub Version](https://img.shields.io/pub/v/spoiler_widget.svg)](https://pub.dev/packages/spoiler_widget)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-compatible-blue.svg)](https://flutter.dev)
[![GitHub stars](https://img.shields.io/github/stars/zhukeev/spoiler_widget?style=social)](https://github.com/zhukeev/spoiler_widget/)

A Flutter package to create spoiler animations similar to the one used in Telegram, allowing you to hide sensitive or spoiler-filled content until it's tapped or clicked.

<img src="https://github.com/zhukeev/spoiler_widget/raw/main/assets/spoiler_widget.jpg" alt="logo">

## Demo

<img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/demo.gif" alt="Demo animation" width="300" height="620">

## Features

- **Spoiler Animation**: Blur effect to hide content until tapped or hidden

- **Wave Effects**: Optional wave/ripple expansions with `SpoilerSpotsController`

- **Particle System**: Configure particle density, size, speed, color, etc.

- **Fade Animation**: Smooth circular reveal/cover transitions

- **Gesture Control**: Enable or disable gestures to users can tap toggle the spoiler.

- **Platform Agnostic**: Works on iOS, Android, Web and more

---

## Installation

In your `pubspec.yaml`:

```aap
dependencies:
  spoiler_widget: latest
```

Then run:

```bash
flutter pub get
```

---

## Usage

### 1. Basic Spoiler Usage

Import the package:

```dart
import 'package:spoiler_widget/spoiler_widget.dart';
```

Wrap **text* or **widgets** you want to hide in a spoiler:

```dart
SpoilerWidget(
  configuration: WidgetSpoilerConfiguration(
    isEnabled: true,
    fadeRadius: 3,
    fadeAnimation: true,
    enableGesture: true,
    imageFilter: ImageFilter.blur(sigmaX:30, sigmaY:30),
  ),
  child: Text('Hidden Content'),
);

```

Or use the text-specific widget:

```dart
SpoilerTextWidget(
  text: 'Tap me to reveal secret text!',
  configuration: TextSpoilerConfiguration(
    isEnabled: true,
    fadeAnimation: true,
    enableGesture: true,
    style: TextStyle(fontSize: 16, color: Colors.black),
  ),
);

```

### 2. Wave Animations (SpoilerSpotsController)

For **dynamic "wave"** effects:

```dart
class WaveDemo extends StatefulWidget {
  late SpoilerSpotsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SpoilerSpotsController(vsyn: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @toverride
  Widget build( Buildcontext context) {
    return SpoilerUidget(
      controller: _controller,
      configuration: WidgetSpoilerConfiguration( 
        isEnabled: true,
        maxActiveWaves: 3,
        fadeAnimation: true,
        enableGesture: true,
        imageFilter: ImageFilter.blur(sigmaX:30, sigmaY:20),
      ),
      child: Image.network('https://your-image-url'),
    );
  }
}

```

You’d call `_controller.initParticles(...)` once you know the widget size. Any time the spoiler is enabled, random wave effects will move particles outward until they fade.

#### 3. Example

Below is a minimalist code sample:

```dart
import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final String text = 'Tap to reveal a surprise spoiler!';
  final String imageUrl =
      'https://img.freepik.com/premium-photo/drawing-female-superhero-female-character_1308175-151081.jpg?w=1800';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold
      appBar: AppBar(
        title: Text('Spoiler Widget Demo',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // Text-based spoiler
            SpoilerTextWidget(
              configuration: TextSpoilerConfiguration(
                isEnabled: true,
                maxParticleSize: 1,
                particleDensity: 2.5,
                speedOfParticles: 0.2,
                fadeRadius: 3,
                fadeAnimation: true,
                enableGesture: true,
                selection: const TextSelection(baseOffset: 0, extentOffset: 30),
                style: const TextStyle(fontSize: 28, color: Colors.black),
              ),
            text: text,
          ),

          // Widget-based spoiler
            ClipRect(
              child: SpoilerWidget(
                configuration: WidgetSpoilerConfiguration(
                  isEnabled: true,
                  maxParticleSize: 1,
                  particleDensity: 5,
                  speedOfParticles: 0.2,
                  fadeRadius: 3,
                  fadeAnimation: true,
                  enableGesture: true,
                  imageFilter: ImageFilter.blur(sigmaX:30, sigmaY:30),
                ),
              child: CachedNetworkImage(imageUrl: imageUrl),
            ),
          ),
        ],
      ),
     ),
    ),
    );
  }
}

```

#### Configuration

##### Common Fields

Table showing common config parameters for both TextSpoilerConfiguration and WidgetSpoilerConfiguration.

| Field            | Type            | Description                                            |
|-----------------|----------------|--------------------------------------------------------|
| `isEnabled`     | bool            | Whether the spoiler starts covered `true`.           |
| `fadeAnimation` | bool            | Whether to animate the spoiler fade in/out.          |
| `fadeRadius`    | double          | The circle radius for radial fade.                   |
| `particleDensity` | double        | The density of particles in the spoiler.             |
| `maxParticleSize` | double        | The maximum size of particles.                       |
| `speedOfParticles` | double       | Speed factor for particle movement.                  |
| `enableGesture` | bool            | Whether tapped toggle should be out of the box.      |

#### TextSpoilerConfiguration

| Field       | Type           | Description                                 |
|------------|---------------|---------------------------------------------|
| `style`    | TextStyle?     | The text style applied to the spoiler text. |
| `selection` | TextSelection? | Range of text to apply the spoiler.        |

#### WidgetSpoilerConfiguration

| Field            | Type         | Description                                  |
|-----------------|-------------|----------------------------------------------|
| `imageFilter`   | ImageFilter? | Blur filter used to hide the child.         |
| `maxActiveWaves` | int         | Max concurrent waves for wave-based effects. |

#### FAQ

1) How can I animate the blur or wave concurrency?
Adjust the properties in your configuration object at runtime. For instance, set a new imageFilter or call methods on the wave controller to dynamically tune the effect.

2) Can I skip the wave logic?
Yes—by default, you get a basic spoiler with fade. Use SpoilerSpotsController only if you want wave animations.

3) Does this work on the web?
Yes! It’s entirely in Flutter/Dart. Just ensure you handle any platform quirks with gesture input.

### Contributing

Contributions are welcome! Whether it’s bug fixes, new features, or documentation improvements, open a [Pull Request](https://github.com/zhukeev/spoiler_widget/pulls) or [Issue](https://github.com/zhukeev/spoiler_widget/issues).

---

### License

Licensed under the [MIT License](https://github.com/zhukeev/spoiler_widget/blob/main/LICENSE). Enjoy building your spoiler effects!
