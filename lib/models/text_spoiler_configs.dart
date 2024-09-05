import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

/// Configuration for the text spoiler widget
/// [style] is the style of the text
/// [selection] is the selection of the text
@immutable
class TextSpoilerConfiguration extends SpoilerConfiguration {
  final TextStyle? style;
  final TextSelection? selection;
  const TextSpoilerConfiguration({
    this.style,
    this.selection,
    super.particleDensity = 20,
    super.speedOfParticles = 0.2,
    super.particleColor = Colors.white70,
    super.maxParticleSize = 1,
    super.fadeAnimation = false,
    super.fadeRadius = 10,
    super.isEnabled = true,
    super.enableGesture = false,
  });
}
