# Spoiler Animation for Flutter

A Flutter package to create spoiler animations similar to the one used in Telegram, allowing you to hide sensitive or spoiler-filled content until it's tapped or clicked.

## Demo

[Demo animation](https://github.com/zhukeev/spoiler_widget/blob/main/example/lib/demo.gif)

## Features

- **Spoiler Animation:** Blur effect hides content until revealed.
- **Customizable:** Adjust blur intensity, animation duration, and more.
- **Easy Integration:** Simple API for adding spoiler animations to your Flutter applications.
- **Platform Agnostic:** Works seamlessly across different platforms supported by Flutter.

## Installation

To use this package, add `spoiler_widget` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  spoiler_widget: ^1.0.4
```

Then, run `flutter pub get` to install the package.

## Usage

Import the package into your Dart code:

```dart
import 'package:spoiler_widget/spoiler_widget.dart';
```

Wrap the content you want to hide with a `SpoilerTextWidget` widget:

```dart
SpoilerTextWidget(
  text: 'This is a spoiler! Tap to reveal.',
),
```

## Example

Here's a simple example demonstrating how to use the package:

```dart
import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {   
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Spoiler Animation Example'),
        ),
        body: Center(
          child: RepaintBoundary(
            child: SpoilerTextWidget(
              enable: true,
              maxParticleSize: 1.5,
              particleDensity: .4,
              speedOfParticles: 0.3,
              fadeRadius: 1,
              fadeAnimation: true,
              enableGesture: true,
              selection: TextSelection(baseOffset: 0, extentOffset: 18),
              text: 'This is a spoiler! Tap to reveal.',
              style: TextStyle(
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
```

## API Reference

### SpoilerAnimation

A widget that creates a spoiler animation to hide content until revealed.

## SpoilerAnimation Properties

| Property           | Type            | Description                                            |
|--------------------|-----------------|--------------------------------------------------------|
| `particleDensity`  | `double`        | The density of particles used in the animation.        |
| `speedOfParticles` | `double`        | The speed of particles in the animation.               |
| `particleColor`    | `Color`         | The color of particles in the animation.               |
| `maxParticleSize`  | `double`        | The maximum size of particles in the animation.        |
| `fadeAnimation`    | `bool`          | Determines whether to apply a fade animation effect.   |
| `fadeRadius`       | `double`        | The radius of the fade effect.                         |
| `enable`           | `bool`          | Determines whether the animation is enabled.           |
| `enableGesture`    | `bool`          | Determines whether gesture recognition is enabled.     |
| `style`            | `TextStyle?`    | The text style to be applied to the spoiler text.      |
| `text`             | `String`        | The text content to be hidden by the spoiler animation.|
| `selection`        | `TextSelection?`| The text selection within the spoiler text.            |

## FAQ

**Q: Can I customize the appearance of the spoiler animation?**

A: Yes, you can adjust parameters like blur intensity and animation duration to customize the appearance and behavior of the spoiler animation.

**Q: Does this package work on all Flutter platforms?**

A: Yes, the package works on iOS, Android, and web platforms without any additional configuration.

## License

This package is licensed under the MIT License. See the [LICENSE](https://github.com/zhukeev/spoiler_widget/LICENSE) file for details.
