// ignore_for_file: deprecated_member_use_from_same_package

part of 'spoiler_configs.dart';

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

  /// The padding over which the fade effect is applied.
  ///
  /// Kept for backward compatibility. When [fadeConfig] is not provided,
  /// this value is used as the source for [FadeConfig.padding].
  @Deprecated('Use fadeConfig.padding instead')
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
    @Deprecated('Use fadeConfig.padding instead') this.fadeRadius,
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
              density:
                  particleDensity ?? ParticleConfig.defaultConfig().density,
              speed: particleSpeed ?? ParticleConfig.defaultConfig().speed,
              color: particleColor ?? ParticleConfig.defaultConfig().color,
              maxParticleSize: maxParticleSize ??
                  ParticleConfig.defaultConfig().maxParticleSize,
            ),
        fadeConfig = _resolveFadeConfig(
          fadeConfig: fadeConfig,
          enableFadeAnimation: enableFadeAnimation,
          fadePadding: fadeRadius,
          fadeEdgeThickness: fadeEdgeThickness,
        ) {
    assert(
      particleConfig == null ||
          (particleDensity == null &&
              particleSpeed == null &&
              particleColor == null &&
              maxParticleSize == null),
    );
    assert(
      fadeConfig == null ||
          (enableFadeAnimation == null &&
              fadeRadius == null &&
              fadeEdgeThickness == null),
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
        particleConfig: ParticleConfig.defaultConfig(),
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
    final bool legacyParticleOverridesProvided = particleDensity != null ||
        particleSpeed != null ||
        particleColor != null ||
        maxParticleSize != null;

    final bool legacyFadeOverridesProvided = enableFadeAnimation != null ||
        fadeRadius != null ||
        fadeEdgeThickness != null;

    final ParticleConfig? nextParticleConfig = legacyParticleOverridesProvided
        ? null
        : (particleConfig ?? this.particleConfig);

    final FadeConfig? nextFadeConfig =
        legacyFadeOverridesProvided ? null : (fadeConfig ?? this.fadeConfig);

    return SpoilerConfig(
      particleDensity: legacyParticleOverridesProvided
          ? (particleDensity ?? this.particleDensity)
          : null,
      particleSpeed: legacyParticleOverridesProvided
          ? (particleSpeed ?? this.particleSpeed)
          : null,
      particleColor: legacyParticleOverridesProvided
          ? (particleColor ?? this.particleColor)
          : null,
      maxParticleSize: legacyParticleOverridesProvided
          ? (maxParticleSize ?? this.maxParticleSize)
          : null,
      enableFadeAnimation: legacyFadeOverridesProvided
          ? (enableFadeAnimation ?? this.enableFadeAnimation)
          : null,
      fadeRadius:
          legacyFadeOverridesProvided ? (fadeRadius ?? this.fadeRadius) : null,
      fadeEdgeThickness: legacyFadeOverridesProvided
          ? (fadeEdgeThickness ?? this.fadeEdgeThickness)
          : null,
      particleConfig: nextParticleConfig,
      fadeConfig: nextFadeConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      enableGestureReveal: enableGestureReveal ?? this.enableGestureReveal,
      maskConfig: maskConfig ?? this.maskConfig,
      onSpoilerVisibilityChanged:
          onSpoilerVisibilityChanged ?? this.onSpoilerVisibilityChanged,
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
