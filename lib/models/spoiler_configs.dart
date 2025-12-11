import 'package:flutter/material.dart';

/// Configuration for the spoiler effect.
///
/// This class defines the behavior and appearance of the spoiler animation,
/// including particle properties, fade effects, and gesture interactions.
///
/// Legacy scalar fields (marked as `@Deprecated`) are preserved for backward
/// compatibility. They are automatically mapped into [particleConfig] and
/// [fadeConfig] when those configs are not provided explicitly. New code
/// should prefer [particleConfig] and [fadeConfig] directly.
@immutable
class SpoilerConfig {
  /// The density of the particles, affecting the number of particles displayed.
  ///
  /// Kept for backward compatibility. When [particleConfig] is not provided,
  /// this value is used as the source for [ParticleConfig.density].
  @Deprecated('Use particleConfig.density instead')
  final double particleDensity;

  /// The speed at which particles move.
  ///
  /// Kept for backward compatibility. When [particleConfig] is not provided,
  /// this value is used as the source for [ParticleConfig.speed].
  @Deprecated('Use particleConfig.speed instead')
  final double particleSpeed;

  /// The color of the particles.
  ///
  /// Kept for backward compatibility. When [particleConfig] is not provided,
  /// this value is used as the source for [ParticleConfig.color].
  @Deprecated('Use particleConfig.color instead')
  final Color particleColor;

  /// The maximum size a particle can have.
  ///
  /// Kept for backward compatibility. When [particleConfig] is not provided,
  /// this value is used as the source for [ParticleConfig.maxParticleSize].
  @Deprecated('Use particleConfig.maxSize instead')
  final double maxParticleSize;

  /// Determines whether the particles will fade out over time.
  ///
  /// Kept for backward compatibility. This flag is used together with
  /// [fadeConfig]; when [fadeConfig] is not provided, the default
  /// [FadeConfig] is created based on the deprecated fade fields.
  @Deprecated('Use fadeConfig instead')
  final bool enableFadeAnimation;

  /// The radius over which the fade effect is applied.
  ///
  /// Kept for backward compatibility. When [fadeConfig] is not provided,
  /// this value is used as the source for [FadeConfig.radius].
  @Deprecated('Use fadeConfig.radius instead')
  final double fadeRadius;

  /// Padding near the fade radius where particles get brighter/larger in shader.
  ///
  /// Kept for backward compatibility. When [fadeConfig] is not provided,
  /// this value is used as the source for [FadeConfig.edgeThickness].
  @Deprecated('Use fadeConfig.edgeThickness instead')
  final double fadeEdgeThickness;

  /// Controls whether the spoiler effect is active.
  final bool isEnabled;

  /// Determines whether user gestures can be used to reveal the spoiler.
  final bool enableGestureReveal;

  /// Optional configuration for applying a custom mask to the spoiler.
  final SpoilerMask? maskConfig;

  /// Optional callback that is invoked when the visibility of the spoiler changes.
  final ValueChanged<bool>? onSpoilerVisibilityChanged;

  /// Optional configuration for applying a custom shader to the spoiler.
  final ShaderConfig? shaderConfig;

  /// Particle configuration.
  ///
  /// This is the preferred way to configure particle behavior. If not
  /// provided in the constructor, it is derived from the deprecated scalar
  /// fields ([particleDensity], [particleSpeed], [particleColor],
  /// [maxParticleSize]) for backward compatibility.
  final ParticleConfig particleConfig;

  /// Fade configuration.
  ///
  /// This is the preferred way to configure fade behavior. If not provided
  /// in the constructor, it is derived from the deprecated fade fields
  /// ([fadeRadius], [fadeEdgeThickness]) for backward compatibility.
  final FadeConfig? fadeConfig;

  /// Constructor for the SpoilerConfig class.
  SpoilerConfig({
    required this.particleDensity,
    required this.particleSpeed,
    required this.particleColor,
    required this.maxParticleSize,
    required this.enableFadeAnimation,
    required this.fadeRadius,
    required this.fadeEdgeThickness,
    required this.isEnabled,
    required this.enableGestureReveal,
    ParticleConfig? particleConfig,
    FadeConfig? fadeConfig,
    this.maskConfig,
    this.onSpoilerVisibilityChanged,
    this.shaderConfig,
  })  : particleConfig = particleConfig ??
            ParticleConfig(
              density: particleDensity,
              speed: particleSpeed,
              color: particleColor,
              maxParticleSize: maxParticleSize,
            ),
        fadeConfig = fadeConfig ??
            (enableFadeAnimation
                ? FadeConfig(
                    radius: fadeRadius,
                    edgeThickness: fadeEdgeThickness,
                  )
                : null);

  /// Returns a default configuration for the spoiler effect.
  ///
  /// This provides a balanced set of default values suitable for most cases.
  factory SpoilerConfig.defaultConfig() => SpoilerConfig(
        particleDensity: 0.1,
        particleSpeed: 0.2,
        particleColor: Colors.white,
        maxParticleSize: 1.0,
        enableFadeAnimation: true,
        fadeRadius: 3.0,
        fadeEdgeThickness: 20.0,
        isEnabled: true,
        enableGestureReveal: true,
      );

  SpoilerConfig copyWith({
    double? particleDensity,
    double? particleSpeed,
    Color? particleColor,
    double? maxParticleSize,
    bool? enableFadeAnimation,
    double? fadeRadius,
    double? fadeEdgeThickness,
    bool? isEnabled,
    bool? enableGestureReveal,
    SpoilerMask? maskConfig,
    ValueChanged<bool>? onSpoilerVisibilityChanged,
    ShaderConfig? shaderConfig,
  }) =>
      SpoilerConfig(
        particleDensity: particleDensity ?? this.particleDensity,
        particleSpeed: particleSpeed ?? this.particleSpeed,
        particleColor: particleColor ?? this.particleColor,
        maxParticleSize: maxParticleSize ?? this.maxParticleSize,
        enableFadeAnimation: enableFadeAnimation ?? this.enableFadeAnimation,
        fadeRadius: fadeRadius ?? this.fadeRadius,
        fadeEdgeThickness: fadeEdgeThickness ?? this.fadeEdgeThickness,
        isEnabled: isEnabled ?? this.isEnabled,
        enableGestureReveal: enableGestureReveal ?? this.enableGestureReveal,
        maskConfig: maskConfig ?? this.maskConfig,
        onSpoilerVisibilityChanged: onSpoilerVisibilityChanged ?? this.onSpoilerVisibilityChanged,
        shaderConfig: shaderConfig ?? this.shaderConfig,
      );

  @override
  int get hashCode => Object.hash(
        particleDensity,
        particleSpeed,
        particleColor,
        maxParticleSize,
        enableFadeAnimation,
        fadeRadius,
        fadeEdgeThickness,
        isEnabled,
        enableGestureReveal,
        maskConfig,
        shaderConfig,
        onSpoilerVisibilityChanged,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpoilerConfig &&
          particleDensity == other.particleDensity &&
          particleSpeed == other.particleSpeed &&
          particleColor == other.particleColor &&
          maxParticleSize == other.maxParticleSize &&
          enableFadeAnimation == other.enableFadeAnimation &&
          fadeRadius == other.fadeRadius &&
          fadeEdgeThickness == other.fadeEdgeThickness &&
          isEnabled == other.isEnabled &&
          enableGestureReveal == other.enableGestureReveal &&
          maskConfig == other.maskConfig &&
          shaderConfig == other.shaderConfig &&
          onSpoilerVisibilityChanged == other.onSpoilerVisibilityChanged;
}

/// Configuration for applying a mask to the spoiler effect.
///
/// A mask defines a specific area where the spoiler effect is applied
/// using a [Path] and a [PathOperation] to determine how the mask interacts
/// with the spoiler area.
class SpoilerMask {
  /// The shape or area used as the mask.
  final Path maskPath;

  /// The operation defining how the mask interacts with the spoiler content.
  final PathOperation maskOperation;

  /// The offset to shift the mask position.
  ///
  /// This allows dynamic positioning of the mask relative to its original placement.
  final Offset offset;

  /// Creates a mask configuration with the given path, operation, and optional offset.
  ///
  /// The [offset] parameter defaults to `Offset.zero`, meaning no shift in position.
  SpoilerMask({
    required this.maskPath,
    required this.maskOperation,
    this.offset = Offset.zero,
  });
}

class ShaderConfig {
  /// Path to a custom fragment shader asset (e.g. 'shaders/particles.frag').
  /// If provided, this shader replaces the default particle effect.
  final String? customShaderPath;

  /// Optional callback to generate shader uniforms for a given rect.
  ///
  /// This callback determines the list of float values passed to the shader
  /// for each rendered frame and particle rect.
  /// The [config] parameter provides access to the current configuration.
  final ShaderCallback? onGetShaderUniforms;

  const ShaderConfig({
    required this.onGetShaderUniforms,
    required this.customShaderPath,
  });
}

typedef ShaderCallback = List<double> Function(
  Rect rect,
  double time,
  double seed,
  Offset fadeCenter,
  bool isFading,
  SpoilerConfig config,
);

class FadeConfig {
  final double radius;
  final double edgeThickness;

  const FadeConfig({
    required this.radius,
    required this.edgeThickness,
  });
}

class ParticleConfig {
  final double density;
  final double speed;
  final Color color;
  final double maxParticleSize;

  ParticleConfig({
    required this.density,
    required this.speed,
    required this.color,
    required this.maxParticleSize,
  });
}
