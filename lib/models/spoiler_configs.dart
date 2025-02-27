import 'package:flutter/material.dart';

/// Configuration for the spoiler widget
/// [particleDensity] is the density of the particles / count of particles
/// [speedOfParticles] is the speed of the particles
/// [particleColor] is the color of the particles
/// [maxParticleSize] is the maximum size of the particles
/// [fadeAnimation] is whether to fade the particles
/// [fadeRadius] is the radius of the fade effect
/// [isEnabled] is whether the spoiler is enabled
/// [enableGesture] is whether to enable gesture to reveal the spoiler
@immutable
class SpoilerConfiguration {
  final double particleDensity;
  final double speedOfParticles;
  final Color particleColor;
  final double maxParticleSize;
  final bool fadeAnimation;
  final double fadeRadius;
  final bool isEnabled;
  final bool enableGesture;

  const SpoilerConfiguration({
    required this.particleDensity,
    required this.speedOfParticles,
    required this.particleColor,
    required this.maxParticleSize,
    required this.fadeAnimation,
    required this.fadeRadius,
    required this.isEnabled,
    required this.enableGesture,
  });

  factory SpoilerConfiguration.defaultConfig() => const SpoilerConfiguration(
        particleDensity: 5.5,
        speedOfParticles: 0.2,
        particleColor: Colors.white,
        maxParticleSize: 1,
        fadeAnimation: true,
        fadeRadius: 3,
        isEnabled: true,
        enableGesture: true,
      );
}
