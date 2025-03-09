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

  /// Creates a text spoiler configuration with the specified parameters.
  ///
  /// Inherits base properties from [SpoilerConfig] while adding
  /// text-specific customizations such as styling, alignment, and selection.
  const TextSpoilerConfig({
    this.textStyle,
    this.textSelection,
    this.textAlign,
    super.particleDensity = 20.0,
    super.particleSpeed = 0.2,
    super.particleColor = Colors.white70,
    super.maxParticleSize = 1.0,
    super.enableFadeAnimation = false,
    super.fadeRadius = 10.0,
    super.isEnabled = true,
    super.enableGestureReveal = false,
    super.maskConfig,
  });
}
