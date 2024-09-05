import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

/// Configuration for the widget spoiler widget
/// [imageFilter] is the image filter to be applied
@immutable
class WidgetSpoilerConfiguration extends SpoilerConfiguration {
  final ImageFilter imageFilter;
  const WidgetSpoilerConfiguration({
    required this.imageFilter,
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
