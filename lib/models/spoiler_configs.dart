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

  /// Optional callback that is invoked when the visibility of the spoiler changes.
  final ValueChanged<bool>? onSpoilerVisibilityChanged;
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
    this.onSpoilerVisibilityChanged,
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
    ValueChanged<bool>? onSpoilerVisibilityChanged,
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
        onSpoilerVisibilityChanged:
            onSpoilerVisibilityChanged ?? this.onSpoilerVisibilityChanged,
      );
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
