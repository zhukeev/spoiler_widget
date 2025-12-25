import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

/// Configuration for the text-based spoiler effect.
///
/// This extends [SpoilerConfig] to provide additional customization options
/// specific to text-based spoilers, such as styling, alignment, and text selection handling.
@immutable
class TextSpoilerConfig extends SpoilerConfig {
  /// The text style to be applied to the spoiler text.
  ///
  /// This allows customization of the font, color, weight, and other
  /// text-related properties.
  final TextStyle? textStyle;

  /// The selection range within the text.
  ///
  /// This defines the portion of the text that should be affected by the
  /// spoiler effect, allowing for partial text obfuscation.
  final TextSelection? textSelection;

  /// The alignment of the text within the spoiler widget.
  ///
  /// This allows controlling the horizontal alignment of the text,
  /// such as [TextAlign.center], [TextAlign.left], [TextAlign.right], etc.
  /// If null, the default alignment of the parent widget will be used.
  final TextAlign? textAlign;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [isEllipsis].
  ///
  /// If this is 1, the text will not wrap. Otherwise, text will wrap at the
  /// edge of the box.
  ///
  /// If this is null, but there is an ambient [DefaultTextStyle] that specifies
  /// an explicit number for its [DefaultTextStyle.maxLines], then the
  /// [DefaultTextStyle] value will take precedence. You can use a [RichText]
  /// widget directly to entirely override the [DefaultTextStyle].
  final int? maxLines;

  /// Determines whether overflowing text should display an ellipsis ("…") at the end.
  ///
  /// If [isEllipsis] is true and the text exceeds [maxLines], a "…" will be
  /// appended to indicate that the text has been truncated.
  ///
  /// If the value is null or false, the ellipsis will not be used
  final bool? isEllipsis;

  /// Creates a text spoiler configuration with the specified parameters.
  ///
  /// Inherits base properties from [SpoilerConfig] while adding
  /// text-specific customizations such as styling, alignment, and selection.
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
    ShaderConfig? shaderConfig,
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
                shapePreset: this.particleConfig.shapePreset,
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
      shaderConfig: shaderConfig ?? this.shaderConfig,
    );
  }

  @override
  int get hashCode => Object.hash(
        particleConfig,
        fadeConfig,
        isEnabled,
        enableGestureReveal,
        maskConfig,
        shaderConfig,
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
          shaderConfig == other.shaderConfig &&
          onSpoilerVisibilityChanged == other.onSpoilerVisibilityChanged &&
          textStyle == other.textStyle &&
          textSelection == other.textSelection &&
          textAlign == other.textAlign &&
          maxLines == other.maxLines &&
          isEllipsis == other.isEllipsis;
}
