# Spoiler Animation for Flutter

![Pub Likes](https://img.shields.io/pub/likes/spoiler_widget)
![Pub Points](https://img.shields.io/pub/points/spoiler_widget)
[![Pub Version](https://img.shields.io/pub/v/spoiler_widget.svg)](https://pub.dev/packages/spoiler_widget)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-compatible-blue.svg)](https://flutter.dev)
[![GitHub stars](https://img.shields.io/github/stars/zhukeev/spoiler_widget?style=social)](https://github.com/zhukeev/spoiler_widget/)

A Flutter package to create spoiler animations similar to the one used in Telegram, allowing you to hide sensitive or spoiler-filled content until it's tapped or clicked.

## Demo

<!-- markdownlint-disable MD033 -->
| Mask Operation | Demo |
|----------------------------|------------------------|
| `PathOperation.intersect`  | <img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/intersect_demo.gif">  |
| `PathOperation.difference` | <img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/difference_demo.gif"> |
| `PathOperation.union`      | <img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/union_demo.gif">      |
| `PathOperation.xor`        | <img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/xor_demo.gif">        |
<!-- markdownlint-enable MD033 -->

## Features

- **Spoiler Animation**: Blur effect to hide content until tapped or hidden

- **Wave Effects**: Optional wave/ripple expansions with `SpoilerSpotsController`

- **Particle System**: Configure particle density, size, speed, color, etc.

- **Fade Animation**: Smooth circular reveal/cover transitions

- **Gesture Control**: Enable or disable gestures to users can tap toggle the spoiler.

- **Masking Support**: Use custom `Path` + `PathOperation` via `maskConfig`.

- **Platform Agnostic**: Works on iOS, Android, Web and more

---

## Installation

In your `pubspec.yaml`:

```yaml
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

Wrap **text** or **widgets** you want to hide in a spoiler:

```dart
SpoilerOverlay(
  config: WidgetSpoilerConfig(
    isEnabled: true,
    fadeRadius: 3,
    enableFadeAnimation: true,
    enableGestureReveal: true,
    imageFilter: ImageFilter.blur(sigmaX:30, sigmaY:30),
    onSpoilerVisibilityChanged: (isVisible) {
      debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
    },
  ),
  child: Text('Hidden Content'),
);

```

Or use the text-specific widget:

```dart
SpoilerText(
  text: 'Tap me to reveal secret text!',
  config: TextSpoilerConfig(
    isEnabled: true,
    enableFadeAnimation: true,
    enableGestureReveal: true,
    textStyle: TextStyle(fontSize: 16, color: Colors.black),
    onSpoilerVisibilityChanged: (isVisible) {
      debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
    },
  ),
  
);

```

### 2. Wave Animations (SpoilerSpotsController)

For **dynamic "wave"** effects:

```dart
class WaveDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SpoilerOverlay(
      config: WidgetSpoilerConfig( 
        isEnabled: true,
        maxActiveWaves: 3,
        enableFadeAnimation: true,
        enableGestureReveal: true,
        imageFilter: ImageFilter.blur(sigmaX:30, sigmaY:20),
        onSpoilerVisibilityChanged: (isVisible) {
          debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
        },
      ),
      child: Image.network('https://your-image-url'),
    );
  }
}

```

### 3. Custom Path Masking

You can apply a custom-shaped mask using `maskConfig` in both `TextSpoilerConfig` and `WidgetSpoilerConfig`.
This allows the spoiler effect to only appear inside specific areas defined by a `Path`.

```dart
SpoilerText(
  text: 'Masked spoiler!',
  config: TextSpoilerConfig(
    isEnabled: true,
    enableGestureReveal: true,
    particleDensity: 0.1,
    textStyle: TextStyle(fontSize: 24, color: Colors.white),
    maskConfig: SpoilerMask(
      maskPath: myCustomPath,
      maskOperation: PathOperation.intersect,
      offset: Offset(50, 30),
    ),
    onSpoilerVisibilityChanged: (isVisible) {
      debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
    },
  ),
);

```

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
            SpoilerText(
              config: TextSpoilerConfig(
                isEnabled: true,
                maxParticleSize: 1,
                particleDensity: .2,
                particleSpeed: 0.2,
                fadeRadius: 3,
                enableFadeAnimation: true,
                enableGestureReveal: true,
                textSelection: const TextSelection(baseOffset: 0, extentOffset: 30),
                textStyle: const TextStyle(fontSize: 28, color: Colors.black),
                onSpoilerVisibilityChanged: (isVisible) {
                  debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
                },
              ),
            text: text,
           
          ),

          // Widget-based spoiler
            ClipRect(
              child: SpoilerOverlay(
                config: WidgetSpoilerConfig(
                  isEnabled: true,
                  maxParticleSize: 1,
                  particleDensity: .2,
                  particleSpeed: 0.2,
                  fadeRadius: 3,
                  enableFadeAnimation: true,
                  enableGestureReveal: true,
                  imageFilter: ImageFilter.blur(sigmaX:30, sigmaY:30),
                  onSpoilerVisibilityChanged: (isVisible) {
                    debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
                  },
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

| Field            | Type            | Description                                                  |
|-----------------|----------------|--------------------------------------------------------------|
| `isEnabled`     | bool            | Whether the spoiler starts covered `true`.                   |
| `enableFadeAnimation` | bool            | Enables smooth fade-in/out.                                  |
| `fadeRadius`    | double          | The circle radius for radial fade.                           |
| `particleDensity` | double        | The density of particles in the spoiler.                     |
| `maxParticleSize` | double        | The maximum size of particles.                               |
| `particleSpeed` | double       | Speed factor for particle movement.                          |
| `enableGestureReveal` | bool            | Whether tapped toggle should be out of the box.              |
| `maskConfig` | SpoilerMask?            | Optional mask to apply using a `Path`.                       |
| `onSpoilerVisibilityChanged` | ValueChanged?            | Optional callback fired when spoiler becomes visible/hidden. |

#### TextSpoilerConfiguration

| Field       | Type           | Description                                 |
|------------|---------------|---------------------------------------------|
| `textStyle`    | TextStyle?     | The text style applied to the spoiler text. |
| `textSelection` | TextSelection? | Range of text to apply the spoiler.        |
| `textAlign` | TextAlign? | Text alignment inside the widget.        |
| `maxLines` | int? |  An optional maximum number of lines for the text to span, wrapping if necessary.        |
| `isEllipsis` | bool? |  Determines whether overflowing text should display an ellipsis ("…") at the end.        |

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
