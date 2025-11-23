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
  const TextSpoilerConfig({
    this.textStyle,
    this.textSelection,
    this.textAlign,
    this.maxLines,
    this.isEllipsis,
    super.particleDensity = 20.0,
    super.particleSpeed = 0.2,
    super.particleColor = Colors.white70,
    super.maxParticleSize = 1.0,
    super.enableFadeAnimation = false,
    super.fadeRadius = 10.0,
    super.isEnabled = true,
    super.enableGestureReveal = false,
    super.maskConfig,
    super.onSpoilerVisibilityChanged,
  });

  @override
  TextSpoilerConfig copyWith({
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
    TextStyle? textStyle,
    TextSelection? textSelection,
    TextAlign? textAlign,
    int? maxLines,
    bool? isEllipsis,
  }) =>
      TextSpoilerConfig(
        particleDensity: particleDensity ?? this.particleDensity,
        particleSpeed: particleSpeed ?? this.particleSpeed,
        particleColor: particleColor ?? this.particleColor,
        maxParticleSize: maxParticleSize ?? this.maxParticleSize,
        enableFadeAnimation: enableFadeAnimation ?? this.enableFadeAnimation,
        fadeRadius: fadeRadius ?? this.fadeRadius,
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
          particleDensity == other.particleDensity &&
          particleSpeed == other.particleSpeed &&
          particleColor == other.particleColor &&
          maxParticleSize == other.maxParticleSize &&
          enableFadeAnimation == other.enableFadeAnimation &&
          fadeRadius == other.fadeRadius &&
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
