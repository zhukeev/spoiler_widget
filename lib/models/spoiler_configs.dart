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
  final double? particleDensity;

  /// The speed at which particles move.
  ///
  /// Kept for backward compatibility. When [particleConfig] is not provided,
  /// this value is used as the source for [ParticleConfig.speed].
  @Deprecated('Use particleConfig.speed instead')
  final double? particleSpeed;

  /// The color of the particles.
  ///
  /// Kept for backward compatibility. When [particleConfig] is not provided,
  /// this value is used as the source for [ParticleConfig.color].
  @Deprecated('Use particleConfig.color instead')
  final Color? particleColor;

  /// The maximum size a particle can have.
  ///
  /// Kept for backward compatibility. When [particleConfig] is not provided,
  /// this value is used as the source for [ParticleConfig.maxParticleSize].
  @Deprecated('Use particleConfig.maxSize instead')
  final double? maxParticleSize;

  /// Determines whether the particles will fade out over time.
  ///
  /// Kept for backward compatibility. This flag is used together with
  /// [fadeConfig]; when [fadeConfig] is not provided, the default
  /// [FadeConfig] is created based on the deprecated fade fields.
  @Deprecated('Use fadeConfig instead')
  final bool? enableFadeAnimation;

  /// The radius over which the fade effect is applied.
  ///
  /// Kept for backward compatibility. When [fadeConfig] is not provided,
  /// this value is used as the source for [FadeConfig.radius].
  @Deprecated('Use fadeConfig.radius instead')
  final double? fadeRadius;

  /// Padding near the fade radius where particles get brighter/larger in shader.
  ///
  /// Kept for backward compatibility. When [fadeConfig] is not provided,
  /// this value is used as the source for [FadeConfig.edgeThickness].
  @Deprecated('Use fadeConfig.edgeThickness instead')
  final double? fadeEdgeThickness;

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

  static const ParticleConfig _defaultParticleConfig = ParticleConfig(
    density: 0.1,
    speed: 0.2,
    color: Colors.white,
    maxParticleSize: 1.0,
  );

  static const FadeConfig _defaultFadeConfig = FadeConfig(
    padding: 3.0,
    edgeThickness: 20.0,
  );

  /// Constructor for the SpoilerConfig class.
  SpoilerConfig({
    @Deprecated('Use particleConfig.density instead') this.particleDensity,
    @Deprecated('Use particleConfig.speed instead') this.particleSpeed,
    @Deprecated('Use particleConfig.color instead') this.particleColor,
    @Deprecated('Use particleConfig.maxSize instead') this.maxParticleSize,
    @Deprecated('Use fadeConfig instead') this.enableFadeAnimation,
    @Deprecated('Use fadeConfig.radius instead') this.fadeRadius,
    @Deprecated('Use fadeConfig.edgeThickness instead') this.fadeEdgeThickness,
    required this.isEnabled,
    required this.enableGestureReveal,
    ParticleConfig? particleConfig,
    FadeConfig? fadeConfig,
    this.maskConfig,
    this.onSpoilerVisibilityChanged,
    this.shaderConfig,
  })  : particleConfig = particleConfig ??
            ParticleConfig(
              density: particleDensity ?? _defaultParticleConfig.density,
              speed: particleSpeed ?? _defaultParticleConfig.speed,
              color: particleColor ?? _defaultParticleConfig.color,
              maxParticleSize: maxParticleSize ?? _defaultParticleConfig.maxParticleSize,
            ),
        fadeConfig = _resolveFadeConfig(
          fadeConfig: fadeConfig,
          enableFadeAnimation: enableFadeAnimation,
          fadePadding: fadeRadius,
          fadeEdgeThickness: fadeEdgeThickness,
        ) {
    assert(
      particleConfig == null ||
          (particleDensity == null && particleSpeed == null && particleColor == null && maxParticleSize == null),
    );
    assert(
      fadeConfig == null || (enableFadeAnimation == null && fadeRadius == null && fadeEdgeThickness == null),
    );
  }

  static FadeConfig? _resolveFadeConfig({
    required FadeConfig? fadeConfig,
    required bool? enableFadeAnimation,
    required double? fadePadding,
    required double? fadeEdgeThickness,
  }) {
    if (fadeConfig != null) return fadeConfig;

    final bool enabled = enableFadeAnimation ?? true;
    if (!enabled) return null;

    return FadeConfig(
      padding: fadePadding ?? _defaultFadeConfig.padding,
      edgeThickness: fadeEdgeThickness ?? _defaultFadeConfig.edgeThickness,
    );
  }

  /// Returns a default configuration for the spoiler effect.
  ///
  /// This provides a balanced set of default values suitable for most cases.
  factory SpoilerConfig.defaultConfig() => SpoilerConfig(
        isEnabled: true,
        enableGestureReveal: true,
        particleConfig: _defaultParticleConfig,
        fadeConfig: _defaultFadeConfig,
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
    ParticleConfig? particleConfig,
    FadeConfig? fadeConfig,
    SpoilerMask? maskConfig,
    ValueChanged<bool>? onSpoilerVisibilityChanged,
    ShaderConfig? shaderConfig,
  }) {
    final bool legacyParticleOverridesProvided =
        particleDensity != null || particleSpeed != null || particleColor != null || maxParticleSize != null;

    final bool legacyFadeOverridesProvided =
        enableFadeAnimation != null || fadeRadius != null || fadeEdgeThickness != null;

    final ParticleConfig? nextParticleConfig =
        legacyParticleOverridesProvided ? null : (particleConfig ?? this.particleConfig);

    final FadeConfig? nextFadeConfig = legacyFadeOverridesProvided ? null : (fadeConfig ?? this.fadeConfig);

    return SpoilerConfig(
      particleDensity: legacyParticleOverridesProvided ? (particleDensity ?? this.particleDensity) : null,
      particleSpeed: legacyParticleOverridesProvided ? (particleSpeed ?? this.particleSpeed) : null,
      particleColor: legacyParticleOverridesProvided ? (particleColor ?? this.particleColor) : null,
      maxParticleSize: legacyParticleOverridesProvided ? (maxParticleSize ?? this.maxParticleSize) : null,
      enableFadeAnimation: legacyFadeOverridesProvided ? (enableFadeAnimation ?? this.enableFadeAnimation) : null,
      fadeRadius: legacyFadeOverridesProvided ? (fadeRadius ?? this.fadeRadius) : null,
      fadeEdgeThickness: legacyFadeOverridesProvided ? (fadeEdgeThickness ?? this.fadeEdgeThickness) : null,
      particleConfig: nextParticleConfig,
      fadeConfig: nextFadeConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      enableGestureReveal: enableGestureReveal ?? this.enableGestureReveal,
      maskConfig: maskConfig ?? this.maskConfig,
      onSpoilerVisibilityChanged: onSpoilerVisibilityChanged ?? this.onSpoilerVisibilityChanged,
      shaderConfig: shaderConfig ?? this.shaderConfig,
    );
  }

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
        particleConfig,
        fadeConfig,
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
          onSpoilerVisibilityChanged == other.onSpoilerVisibilityChanged &&
          particleConfig == other.particleConfig &&
          fadeConfig == other.fadeConfig;
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

  static List<double> _particleUniforms(
    Rect rect,
    double time,
    double seed,
    Offset fadeOffset,
    bool isFading,
    double fadeRadius,
    SpoilerConfig config,
  ) {
    return [
      // 1. uResolution
      rect.width,
      rect.height,
      // 2. uTime
      time,
      // 3. uRect
      rect.left,
      rect.top,
      rect.width,
      rect.height,
      // 4. uSeed
      seed,
      // 5. uColor
      config.particleConfig.color.red / 255.0,
      config.particleConfig.color.green / 255.0,
      config.particleConfig.color.blue / 255.0,
      // 6. uDensity
      config.particleConfig.density,
      // 7. uSize
      config.particleConfig.maxParticleSize,
      // 8. uSpeed
      config.particleConfig.speed,
      // 9. uFadeCenter
      fadeOffset.dx,
      fadeOffset.dy,
      // 10. uFadeRadius
      fadeRadius,
      // 11. uIsFading
      isFading ? 1.0 : 0.0,
      // 12. uFadeEdgeThickness
      // (config.fadeConfig?.edgeThickness ?? 1.0) * 10.0,
      (config.fadeConfig?.edgeThickness ?? 1.0),
      // 13. uEnableWaves
      config.particleConfig.enableWaves ? 1.0 : 0.0,
      // 14. uMaxWaveRadius
      config.particleConfig.maxWaveRadius,
      // 15. uMaxWaveCount
      config.particleConfig.maxWaveCount.toDouble(),
    ];
  }

  static List<double> _baseUniforms(
    Rect rect,
    double time,
    double seed,
    Offset fadeOffset,
    bool isFading,
    double fadeRadius,
    SpoilerConfig config,
  ) {
    return [
      // 1. uResolution
      rect.width,
      rect.height,
      // 2. uTime
      time,
      // 3. uRect
      rect.left,
      rect.top,
      rect.width,
      rect.height,
      // 4. uSeed
      seed,
      // 5. uColor
      config.particleConfig.color.red / 255.0,
      config.particleConfig.color.green / 255.0,
      config.particleConfig.color.blue / 255.0,
      // 6. uDensity
      config.particleConfig.density,
      // 7. uSize
      config.particleConfig.maxParticleSize,
      // 8. uSpeed
      config.particleConfig.speed,
      // 9. uFadeCenter
      fadeOffset.dx,
      fadeOffset.dy,
      // 10. uFadeRadius
      fadeRadius,
      // 11. uIsFading
      isFading ? 1.0 : 0.0,
      // 12. uEdgeThickness
      (config.fadeConfig?.edgeThickness ?? 1.0) * 10.0,
    ];
  }

  factory ShaderConfig.particles() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/particles.frag',
        onGetShaderUniforms: _particleUniforms,
      );

  factory ShaderConfig.bokehCover() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/bokeh_cover.frag',
        onGetShaderUniforms: _baseUniforms,
      );

  /// Liquid Metal (CC0) warped FBM shader.
  factory ShaderConfig.liquidMetal() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/liquid_metal.frag',
        onGetShaderUniforms: _baseUniforms,
      );

  /// Glitch stripes with RGB splits.
  factory ShaderConfig.glitchStripes() => ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/glitch_stripes.frag',
        onGetShaderUniforms: (rect, time, seed, fadeOffset, isFading, fadeRadius, config) {
          return [
            rect.width,
            rect.height,
            time,
            rect.left,
            rect.top,
            rect.width,
            rect.height,
            seed,
            config.particleConfig.color.red / 255.0,
            config.particleConfig.color.green / 255.0,
            config.particleConfig.color.blue / 255.0,
            config.particleConfig.density,
            config.particleConfig.speed,
            fadeOffset.dx,
            fadeOffset.dy,
            fadeRadius,
            isFading ? 1.0 : 0.0,
            (config.fadeConfig?.edgeThickness ?? 1.0) * 10.0,
          ];
        },
      );

  /// Pixelated mosaic censor blocks.
  factory ShaderConfig.mosaicCensor() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/mosaic_censor.frag',
        onGetShaderUniforms: _baseUniforms,
      );

  /// Liquid Spectrum (HSV FBM) shader.
  factory ShaderConfig.liquidSpectrum() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/liquid_spectrum.frag',
        onGetShaderUniforms: _baseUniforms,
      );
}

typedef ShaderCallback = List<double> Function(
  Rect rect,
  double time,
  double seed,
  Offset fadeCenter,
  bool isFading,
  double fadeRadius,
  SpoilerConfig config,
);

@immutable
class FadeConfig {
  final double padding;
  final double edgeThickness;

  const FadeConfig({
    required this.padding,
    required this.edgeThickness,
  });

  @override
  int get hashCode => Object.hash(padding, edgeThickness);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FadeConfig && padding == other.padding && edgeThickness == other.edgeThickness;
}

@immutable
class ParticleConfig {
  final double density;
  final double speed;
  final Color color;
  final double maxParticleSize;
  final bool enableWaves;
  final double maxWaveRadius;
  final int maxWaveCount;

  const ParticleConfig({
    required this.density,
    required this.speed,
    required this.color,
    required this.maxParticleSize,
    this.enableWaves = false,
    this.maxWaveRadius = 0.0,
    this.maxWaveCount = 3,
  });

  @override
  int get hashCode => Object.hash(density, speed, color, maxParticleSize, enableWaves, maxWaveRadius, maxWaveCount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleConfig &&
          density == other.density &&
          speed == other.speed &&
          color == other.color &&
          maxParticleSize == other.maxParticleSize &&
          enableWaves == other.enableWaves &&
          maxWaveRadius == other.maxWaveRadius &&
          maxWaveCount == other.maxWaveCount;
}
