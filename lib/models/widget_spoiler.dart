import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

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
  const WidgetSpoilerConfig({
    required this.imageFilter,
    this.maxActiveWaves = 4,
    super.particleDensity = 0.1,
    super.particleSpeed = 0.2,
    super.particleColor = Colors.white,
    super.maxParticleSize = 1.0,
    super.enableFadeAnimation = false,
    super.fadeRadius = 10.0,
    super.isEnabled = true,
    super.enableGestureReveal = false,
    super.maskConfig,
  });

  /// Returns a default configuration for the widget spoiler effect.
  ///
  /// This includes a strong blur effect and other default settings.
  factory WidgetSpoilerConfig.defaultConfig() => WidgetSpoilerConfig(
        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      );
}
