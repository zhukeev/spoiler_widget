import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

/// Internal helpers shared by the spoiler config `copyWith` implementations.
///
/// This library is intentionally not exported by `spoiler_widget.dart`.

/// Returns true when any legacy scalar particle parameter is set.
bool hasLegacyParticleOverrides(
  double? particleDensity,
  double? particleSpeed,
  Color? particleColor,
  double? maxParticleSize,
) =>
    particleDensity != null ||
    particleSpeed != null ||
    particleColor != null ||
    maxParticleSize != null;

/// Returns true when any legacy scalar fade parameter is set.
bool hasLegacyFadeOverrides(
  bool? enableFadeAnimation,
  double? fadeRadius,
  double? fadeEdgeThickness,
) =>
    enableFadeAnimation != null ||
    fadeRadius != null ||
    fadeEdgeThickness != null;

/// Rebuilds a [ParticleConfig] from legacy scalar overrides, falling back to
/// [base] per field. Preserves all non-scalar fields (shape preset, waves).
ParticleConfig mergeLegacyParticleConfig(
  ParticleConfig base, {
  double? particleDensity,
  double? particleSpeed,
  Color? particleColor,
  double? maxParticleSize,
}) => ParticleConfig(
  density: particleDensity ?? base.density,
  speed: particleSpeed ?? base.speed,
  color: particleColor ?? base.color,
  maxParticleSize: maxParticleSize ?? base.maxParticleSize,
  shapePreset: base.shapePreset,
  enableWaves: base.enableWaves,
  maxWaveRadius: base.maxWaveRadius,
  maxWaveCount: base.maxWaveCount,
);

/// Rebuilds a [FadeConfig] from legacy scalar overrides, falling back to
/// [base]. Returns null when fade is disabled.
FadeConfig? mergeLegacyFadeConfig(
  FadeConfig? base, {
  bool? enableFadeAnimation,
  double? fadeRadius,
  double? fadeEdgeThickness,
}) {
  final enabled = enableFadeAnimation ?? (base != null);
  if (!enabled) return null;
  return FadeConfig(
    padding: fadeRadius ?? (base?.padding ?? 10.0),
    edgeThickness: fadeEdgeThickness ?? (base?.edgeThickness ?? 20.0),
  );
}
