import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

/// Configuration for the widget spoiler widget
/// [imageFilter] is the image filter to be applied
@immutable
class WidgetSpoilerConfiguration extends SpoilerConfiguration {
  final ImageFilter imageFilter;
  final int maxActiveWaves;
  const WidgetSpoilerConfiguration({
    required this.imageFilter,
    this.maxActiveWaves = 4,
    super.particleDensity = .1,
    super.speedOfParticles = 0.2,
    super.particleColor = Colors.white,
    super.maxParticleSize = 1,
    super.fadeAnimation = false,
    super.fadeRadius = 10,
    super.isEnabled = true,
    super.enableGesture = false,
  });

  factory WidgetSpoilerConfiguration.defaultConfig() => WidgetSpoilerConfiguration(
        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      );
}
