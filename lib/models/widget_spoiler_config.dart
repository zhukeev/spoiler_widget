import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

@immutable
class WidgetSpoilerConfig extends SpoilerConfig {
  final ImageFilter imageFilter;
  final int maxActiveWaves;

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
    bool isEnabled = true,
    bool enableGestureReveal = false,
    SpoilerMask? maskConfig,
    ValueChanged<bool>? onSpoilerVisibilityChanged,
    ShaderConfig? shaderConfig,
    ParticleConfig? particleConfig,
    FadeConfig? fadeConfig,
  }) : super(
          isEnabled: isEnabled,
          enableGestureReveal: enableGestureReveal,
          maskConfig: maskConfig,
          onSpoilerVisibilityChanged: onSpoilerVisibilityChanged,
          shaderConfig: shaderConfig,
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
    final bool legacyParticleOverridesProvided =
        particleDensity != null || particleSpeed != null || particleColor != null || maxParticleSize != null;

    final ParticleConfig nextParticleConfig = particleConfig ??
        (legacyParticleOverridesProvided
            ? ParticleConfig(
                density: particleDensity ?? this.particleConfig.density,
                speed: particleSpeed ?? this.particleConfig.speed,
                color: particleColor ?? this.particleConfig.color,
                maxParticleSize: maxParticleSize ?? this.particleConfig.maxParticleSize,
              )
            : this.particleConfig);

    final bool legacyFadeOverridesProvided =
        enableFadeAnimation != null || fadeRadius != null || fadeEdgeThickness != null;

    final FadeConfig? nextFadeConfig = fadeConfig ??
        (legacyFadeOverridesProvided
            ? ((enableFadeAnimation ?? (this.fadeConfig != null))
                ? FadeConfig(
                    padding: fadeRadius ?? (this.fadeConfig?.padding ?? 10.0),
                    edgeThickness: fadeEdgeThickness ?? (this.fadeConfig?.edgeThickness ?? 20.0),
                  )
                : null)
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
      onSpoilerVisibilityChanged: onSpoilerVisibilityChanged ?? this.onSpoilerVisibilityChanged,
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
