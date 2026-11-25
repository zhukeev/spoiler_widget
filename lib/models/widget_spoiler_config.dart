import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/src/config_resolution.dart';

/// Configuration for the widget-based spoiler effect.
///
/// This extends [SpoilerConfig] and adds additional properties specific to
/// widgets, including an image filter effect and wave animations.
@immutable
class WidgetSpoilerConfig extends SpoilerConfig {
  /// The image filter applied to the widget when the spoiler is active.
  ///
  /// This can be used to blur, pixelate, or otherwise obscure the content
  /// before it is revealed.
  final ImageFilter imageFilter;

  /// The maximum number of active waves used for the spoiler effect.
  ///
  /// This controls how many simultaneous wave animations are allowed when
  /// interacting with the spoiler.
  final int maxActiveWaves;

  /// Creates a widget spoiler configuration with the specified parameters.
  ///
  /// Inherits base properties from [SpoilerConfig] while adding an image filter
  /// and wave control for additional customization.
  WidgetSpoilerConfig({
    required this.imageFilter,
    this.maxActiveWaves = 4,
    double particleDensity = 0.1,
    double particleSpeed = 0.2,
    Color particleColor = Colors.white,
    double maxParticleSize = 1.0,
    bool enableFadeAnimation = false,
    double fadeRadius = 10.0,
    double fadeEdgeThickness = 20.0,
    super.isEnabled = true,
    super.enableGestureReveal = false,
    super.maskConfig,
    super.onSpoilerVisibilityChanged,
    super.shaderConfig,
    ParticleConfig? particleConfig,
    FadeConfig? fadeConfig,
  }) : super(
          particleConfig: particleConfig ??
              ParticleConfig(
                density: particleDensity,
                speed: particleSpeed,
                color: particleColor,
                maxParticleSize: maxParticleSize,
              ),
          fadeConfig: fadeConfig ??
              (enableFadeAnimation
                  ? FadeConfig(
                      padding: fadeRadius,
                      edgeThickness: fadeEdgeThickness,
                    )
                  : null),
        );

  /// Returns a default configuration for the widget spoiler effect.
  ///
  /// This includes a strong blur effect and other default settings.
  factory WidgetSpoilerConfig.defaultConfig() => WidgetSpoilerConfig(
        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      );

  @override
  WidgetSpoilerConfig copyWith({
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
    FadeConfig? fadeConfig,
    ParticleConfig? particleConfig,
    ImageFilter? imageFilter,
    int? maxActiveWaves,
  }) {
    final bool legacyParticleOverrides = hasLegacyParticleOverrides(
      particleDensity,
      particleSpeed,
      particleColor,
      maxParticleSize,
    );

    final ParticleConfig nextParticleConfig = particleConfig ??
        (legacyParticleOverrides
            ? mergeLegacyParticleConfig(
                this.particleConfig,
                particleDensity: particleDensity,
                particleSpeed: particleSpeed,
                particleColor: particleColor,
                maxParticleSize: maxParticleSize,
              )
            : this.particleConfig);

    final bool legacyFadeOverrides = hasLegacyFadeOverrides(
      enableFadeAnimation,
      fadeRadius,
      fadeEdgeThickness,
    );

    final FadeConfig? nextFadeConfig = fadeConfig ??
        (legacyFadeOverrides
            ? mergeLegacyFadeConfig(
                this.fadeConfig,
                enableFadeAnimation: enableFadeAnimation,
                fadeRadius: fadeRadius,
                fadeEdgeThickness: fadeEdgeThickness,
              )
            : this.fadeConfig);

    return WidgetSpoilerConfig(
      imageFilter: imageFilter ?? this.imageFilter,
      maxActiveWaves: maxActiveWaves ?? this.maxActiveWaves,
      shaderConfig: shaderConfig ?? this.shaderConfig,
      particleConfig: nextParticleConfig,
      fadeConfig: nextFadeConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      enableGestureReveal: enableGestureReveal ?? this.enableGestureReveal,
      maskConfig: maskConfig ?? this.maskConfig,
      onSpoilerVisibilityChanged:
          onSpoilerVisibilityChanged ?? this.onSpoilerVisibilityChanged,
    );
  }

  @override
  int get hashCode => Object.hash(
        imageFilter,
        maxActiveWaves,
        particleConfig,
        fadeConfig,
        isEnabled,
        enableGestureReveal,
        maskConfig,
        onSpoilerVisibilityChanged,
        shaderConfig,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetSpoilerConfig &&
          imageFilter == other.imageFilter &&
          maxActiveWaves == other.maxActiveWaves &&
          particleConfig == other.particleConfig &&
          fadeConfig == other.fadeConfig &&
          isEnabled == other.isEnabled &&
          enableGestureReveal == other.enableGestureReveal &&
          maskConfig == other.maskConfig &&
          onSpoilerVisibilityChanged == other.onSpoilerVisibilityChanged &&
          shaderConfig == other.shaderConfig;
}
