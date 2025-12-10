import 'package:flutter/material.dart';

/// Configuration for the spoiler effect.
///
/// This class defines the behavior and appearance of the spoiler animation,
/// including particle properties, fade effects, and gesture interactions.
@immutable
class SpoilerConfig {
  /// The density of the particles, affecting the number of particles displayed.
  final double particleDensity;

  /// The speed at which particles move.
  final double particleSpeed;

  /// The color of the particles.
  final Color particleColor;

  /// The maximum size a particle can have.
  final double maxParticleSize;

  /// Determines whether the particles will fade out over time.
  final bool enableFadeAnimation;

  /// The radius over which the fade effect is applied.
  final double fadeRadius;

  /// Controls whether the spoiler effect is active.
  final bool isEnabled;

  /// Determines whether user gestures can be used to reveal the spoiler.
  final bool enableGestureReveal;

  /// Optional configuration for applying a custom mask to the spoiler.
  final SpoilerMask? maskConfig;

  /// Path to a custom fragment shader asset (e.g. 'shaders/my_clouds.frag').
  /// If provided, this shader replaces the default particle effect.
  final String? customShaderPath;

  /// Optional callback that is invoked when the visibility of the spoiler changes.
  final ValueChanged<bool>? onSpoilerVisibilityChanged;

  /// Optional callback to generate shader uniforms for a given rect.
  ///
  /// This callback determines the list of float values passed to the shader
  /// for each rendered frame and particle rect.
  /// The [config] parameter provides access to the current configuration.
  final List<double> Function(Rect rect, double time, double seed, SpoilerConfig config)? onGetShaderUniforms;
  const SpoilerConfig({
    required this.particleDensity,
    required this.particleSpeed,
    required this.particleColor,
    required this.maxParticleSize,
    required this.enableFadeAnimation,
    required this.fadeRadius,
    required this.isEnabled,
    required this.enableGestureReveal,
    this.maskConfig,
    this.customShaderPath,
    this.onSpoilerVisibilityChanged,
    this.onGetShaderUniforms,
  });

  /// Returns a default configuration for the spoiler effect.
  ///
  /// This provides a balanced set of default values suitable for most cases.
  factory SpoilerConfig.defaultConfig() => const SpoilerConfig(
        particleDensity: 0.1,
        particleSpeed: 0.2,
        particleColor: Colors.white,
        maxParticleSize: 1.0,
        enableFadeAnimation: true,
        fadeRadius: 3.0,
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
    bool? isEnabled,
    bool? enableGestureReveal,
    SpoilerMask? maskConfig,
    String? customShaderPath,
    ValueChanged<bool>? onSpoilerVisibilityChanged,
    List<double> Function(Rect rect, double time, double seed, SpoilerConfig config)? onGetShaderUniforms,
  }) =>
      SpoilerConfig(
        particleDensity: particleDensity ?? this.particleDensity,
        particleSpeed: particleSpeed ?? this.particleSpeed,
        particleColor: particleColor ?? this.particleColor,
        maxParticleSize: maxParticleSize ?? this.maxParticleSize,
        enableFadeAnimation: enableFadeAnimation ?? this.enableFadeAnimation,
        fadeRadius: fadeRadius ?? this.fadeRadius,
        isEnabled: isEnabled ?? this.isEnabled,
        enableGestureReveal: enableGestureReveal ?? this.enableGestureReveal,
        maskConfig: maskConfig ?? this.maskConfig,
        customShaderPath: customShaderPath ?? this.customShaderPath,
        onSpoilerVisibilityChanged: onSpoilerVisibilityChanged ?? this.onSpoilerVisibilityChanged,
        onGetShaderUniforms: onGetShaderUniforms ?? this.onGetShaderUniforms,
      );

  @override
  int get hashCode => Object.hash(
        particleDensity,
        particleSpeed,
        particleColor,
        maxParticleSize,
        enableFadeAnimation,
        fadeRadius,
        isEnabled,
        enableGestureReveal,
        maskConfig,
        customShaderPath,
        onSpoilerVisibilityChanged,
        onGetShaderUniforms,
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
          isEnabled == other.isEnabled &&
          enableGestureReveal == other.enableGestureReveal &&
          maskConfig == other.maskConfig &&
          customShaderPath == other.customShaderPath &&
          onSpoilerVisibilityChanged == other.onSpoilerVisibilityChanged &&
          onGetShaderUniforms == other.onGetShaderUniforms;
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
