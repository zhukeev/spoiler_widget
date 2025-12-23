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
| Mask Operation | Demo | Mask Operation | Demo |
|----------------------------|------------------------|----------------------------|------------------------|
| `PathOperation.intersect`  | <img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/intersect_demo.gif"> | `PathOperation.difference` | <img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/difference_demo.gif"> |
| `PathOperation.union`      | <img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/union_demo.gif"> | `PathOperation.xor`        | <img src="https://github.com/zhukeev/spoiler_widget/raw/main/example/lib/xor_demo.gif"> |
<!-- markdownlint-enable MD033 -->

## Features

- **Spoiler Animation**: Blur effect to hide content until tapped or hidden

- **Wave Effects**: Optional wave/ripple expansions with `SpoilerSpotsController`

- **Particle System**: Configure particle density (0–1 coverage), size, speed, color, and shape.

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
    fadeConfig: FadeConfig(radius: 3.0),
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
    fadeConfig: FadeConfig(radius: 3.0),
    enableGestureReveal: true,
    textStyle: TextStyle(fontSize: 16, color: Colors.black),
    onSpoilerVisibilityChanged: (isVisible) {
      debugPrint('Spoiler is now: ${isVisible ? 'Visible' : 'Hidden'}');
    },
  ),
);

```

### 1.1 Wrap existing text widgets

If you already have a text subtree and just need to hide it with particles, use `SpoilerTextWrapper`:

```dart
SpoilerTextWrapper(
  config: SpoilerConfig(
    isEnabled: true,
    fadeConfig: const FadeConfig(),
    enableGestureReveal: true,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text('Sensitive line 1'),
      Text('Sensitive line 2'),
    ],
  ),
);
```

### 1.2 Form field integration

Use `SpoilerTextFormField` to keep the native context menu/cursor while hiding parts of the input:

```dart
final controller = TextEditingController(text: 'Type here...');

SpoilerTextFormField(
  controller: controller,
  focusNode: FocusNode(),
  config: const TextSpoilerConfig(
    isEnabled: true,
    fadeConfig: FadeConfig(),
    enableGestureReveal: true,
    textSelection: TextSelection(baseOffset: 0, extentOffset: 5),
    textStyle: TextStyle(fontSize: 18, color: Colors.white),
  ),
  cursorColor: Colors.deepPurple,
  maxLines: 3,
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
        fadeConfig: const FadeConfig(),
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
    particleConfig: const ParticleConfig(
      density: 0.1,
      shape: ParticleShape.circle,
    ),
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

#### 3. Full Example

You can find a complete, runnable example in the [example/lib/main.dart](https://github.com/zhukeev/spoiler_widget/blob/main/example/lib/main.dart) file. It demonstrates various configuration options and both text and widget-based spoilers.

#### Configuration

##### Common Fields

Table showing common config parameters for both TextSpoilerConfiguration and WidgetSpoilerConfiguration.

| Field            | Type            | Description                                                  |
|------------------|-----------------|--------------------------------------------------------------|
| `isEnabled`      | bool            | Whether the spoiler starts covered `true`.                   |
| `enableFadeAnimation` | bool       | Enables smooth fade-in/out.<br/>Deprecated, use `fadeConfig`.|
| `fadeRadius`     | double          | Deprecated, use `fadeConfig`.                                |
| `particleDensity`| double          | Deprecated, use `particleConfig`.                            |
| `maxParticleSize`| double          | Deprecated, use `particleConfig`.                            |
| `particleSpeed`  | double          | Deprecated, use `particleConfig`.                            |
| `particleColor`  | Color           | Deprecated, use `particleConfig`.                            |
| `fadeEdgeThickness` | double       | Deprecated, use `fadeConfig`.                                |
| `particleConfig` | ParticleConfig? | Particle system parameters (density, speed, color, size, shape). |
| `fadeConfig`     | FadeConfig?     | Fade animation parameters (radius, edge thickness).          |
| `shaderConfig`   | ShaderConfig?   | Custom fragment shader configuration for particles.          |
| `enableGestureReveal` | bool       | Whether tapped toggle should be out of the box.              |
| `maskConfig`     | SpoilerMask?    | Optional mask to apply using a `Path`.                       |
| `onSpoilerVisibilityChanged` | ValueChanged? | Optional callback fired when spoiler becomes visible/hidden. |

#### ParticleConfig

| Field | Type | Description |
|-------|------|-------------|
| `density` | double | Area coverage percentage in the range 0..1 (0 = 0%, 1 = 100%). Values are clamped. |
| `speed` | double | Particle speed (px/frame). |
| `color` | Color | Base particle color. |
| `maxParticleSize` | double | Particle diameter in pixels. |
| `shape` | ParticleShape | `circle`, `star`, or `snowflake`. Works in both atlas and shader (SDF). |
| `enableWaves` | bool | Enables ripple waves that push particles. |
| `maxWaveRadius` | double | Wave radius limit in pixels. |
| `maxWaveCount` | int | Maximum number of simultaneous waves. |

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

### Dual Rendering Modes

`spoiler_widget` now supports two modes of rendering particles:

1.  **Atlas Rendering** (Default): Uses Flutter's `drawRawAtlas`. This is a CPU-driven approach that is highly efficient for most standard spoiler effects.
2.  **Shader Rendering** (GPU): Uses custom fragment shaders to render particles. This is ideal for complex visual effects and leverages GPU power for smoother performance on high-end devices.

To enable **Shader Rendering**, simply provide a `ShaderConfig` to your spoiler configuration.

### Particle Shapes

Pick a shape once in `ParticleConfig`, and it works for both atlas and shader modes:

```dart
particleConfig: const ParticleConfig(
  density: 0.1,
  shape: ParticleShape.snowflake,
),
```

### 4. Custom Fragment Shader (particles.frag)

You can use the default high-performance shader for particle rendering:

```dart
SpoilerTextWrapper(
  config: SpoilerConfig(
    isEnabled: true,
    enableGestureReveal: true,
    particleConfig: const ParticleConfig(
      density: 0.15,
      speed: 0.25,
      color: Colors.white,
      shape: ParticleShape.star,
    ),
    shaderConfig: ShaderConfig.particles(),
  ),
  child: const Text('GPU-driven particles!'),
);
```

### Contributing

Contributions are welcome! Whether it’s bug fixes, new features, or documentation improvements, open a [Pull Request](https://github.com/zhukeev/spoiler_widget/pulls) or [Issue](https://github.com/zhukeev/spoiler_widget/issues).

---

### License

Licensed under the [MIT License](https://github.com/zhukeev/spoiler_widget/blob/main/LICENSE). Enjoy building your spoiler effects!
