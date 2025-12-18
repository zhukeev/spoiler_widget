import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

@immutable
class TextSpoilerConfig extends SpoilerConfig {
  final TextStyle? textStyle;
  final TextSelection? textSelection;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool? isEllipsis;

  TextSpoilerConfig({
    this.textStyle,
    this.textSelection,
    this.textAlign,
    this.maxLines,
    this.isEllipsis,
    double particleDensity = 20.0,
    double particleSpeed = 0.2,
    Color particleColor = Colors.white70,
    double maxParticleSize = 1.0,
    bool enableFadeAnimation = false,
    double fadeRadius = 10.0,
    double fadeEdgeThickness = 20.0,
    bool isEnabled = true,
    bool enableGestureReveal = false,
    SpoilerMask? maskConfig,
    ValueChanged<bool>? onSpoilerVisibilityChanged,
    ParticleConfig? particleConfig,
    FadeConfig? fadeConfig,
  }) : super(
          isEnabled: isEnabled,
          enableGestureReveal: enableGestureReveal,
          maskConfig: maskConfig,
          onSpoilerVisibilityChanged: onSpoilerVisibilityChanged,
          shaderConfig: null,
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

  @override
  TextSpoilerConfig copyWith({
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
    TextStyle? textStyle,
    TextSelection? textSelection,
    TextAlign? textAlign,
    int? maxLines,
    bool? isEllipsis,
  }) {
    final bool legacyParticleOverrides =
        particleDensity != null || particleSpeed != null || particleColor != null || maxParticleSize != null;

    final ParticleConfig nextParticleConfig = particleConfig ??
        (legacyParticleOverrides
            ? ParticleConfig(
                density: particleDensity ?? this.particleConfig.density,
                speed: particleSpeed ?? this.particleConfig.speed,
                color: particleColor ?? this.particleConfig.color,
                maxParticleSize: maxParticleSize ?? this.particleConfig.maxParticleSize,
              )
            : this.particleConfig);

    final bool legacyFadeOverrides = enableFadeAnimation != null || fadeRadius != null || fadeEdgeThickness != null;

    final FadeConfig? nextFadeConfig = fadeConfig ??
        (legacyFadeOverrides
            ? ((enableFadeAnimation ?? (this.fadeConfig != null))
                ? FadeConfig(
                    padding: fadeRadius ?? (this.fadeConfig?.padding ?? 10.0),
                    edgeThickness: fadeEdgeThickness ?? (this.fadeConfig?.edgeThickness ?? 20.0),
                  )
                : null)
            : this.fadeConfig);

    return TextSpoilerConfig(
      particleConfig: nextParticleConfig,
      fadeConfig: nextFadeConfig,
      isEnabled: isEnabled ?? this.isEnabled,
      enableGestureReveal: enableGestureReveal ?? this.enableGestureReveal,
      maskConfig: maskConfig ?? this.maskConfig,
      onSpoilerVisibilityChanged: onSpoilerVisibilityChanged ?? this.onSpoilerVisibilityChanged,
      textStyle: textStyle ?? this.textStyle,
      textSelection: textSelection ?? this.textSelection,
      textAlign: textAlign ?? this.textAlign,
      maxLines: maxLines ?? this.maxLines,
      isEllipsis: isEllipsis ?? this.isEllipsis,
    );
  }

  @override
  int get hashCode => Object.hash(
        particleConfig,
        fadeConfig,
        isEnabled,
        enableGestureReveal,
        maskConfig,
        onSpoilerVisibilityChanged,
        textStyle,
        textSelection,
        textAlign,
        maxLines,
        isEllipsis,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSpoilerConfig &&
          particleConfig == other.particleConfig &&
          fadeConfig == other.fadeConfig &&
          isEnabled == other.isEnabled &&
          enableGestureReveal == other.enableGestureReveal &&
          maskConfig == other.maskConfig &&
          onSpoilerVisibilityChanged == other.onSpoilerVisibilityChanged &&
          textStyle == other.textStyle &&
          textSelection == other.textSelection &&
          textAlign == other.textAlign &&
          maxLines == other.maxLines &&
          isEllipsis == other.isEllipsis;
}
