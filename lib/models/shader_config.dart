part of 'spoiler_configs.dart';

typedef ShaderCallback = List<double> Function(
  Rect rect,
  double time,
  double seed,
  Offset fadeCenter,
  bool isFading,
  double fadeRadius,
  SpoilerConfig config,
);

class ShaderConfig {
  /// Path to a custom fragment shader asset (e.g. 'shaders/particles.frag').
  /// If provided, this shader replaces the default particle effect.
  final String? customShaderPath;

  /// Optional callback to generate shader uniforms for a given rect.
  ///
  /// This callback determines the list of float values passed to the shader
  /// for each rendered frame and particle rect.
  /// The [config] parameter provides access to the current configuration.
  final ShaderCallback? onGetShaderUniforms;

  const ShaderConfig({
    required this.onGetShaderUniforms,
    required this.customShaderPath,
  });

  static List<double> _particleUniforms(
    Rect rect,
    double time,
    double seed,
    Offset fadeOffset,
    bool isFading,
    double fadeRadius,
    SpoilerConfig config,
  ) {
    return [
      // 1. uResolution
      rect.width,
      rect.height,
      // 2. uTime
      time,
      // 3. uRect
      rect.left,
      rect.top,
      rect.width,
      rect.height,
      // 4. uSeed
      seed,
      // 5. uColor
      config.particleConfig.color.r,
      config.particleConfig.color.g,
      config.particleConfig.color.b,
      // 6. uDensity
      config.particleConfig.density.clamp(0.0, 1.0),
      // 7. uSize
      config.particleConfig.maxParticleSize,
      // 8. uSpeed
      config.particleConfig.speed,
      // 9. uFadeCenter
      fadeOffset.dx,
      fadeOffset.dy,
      // 10. uFadeRadius
      fadeRadius,
      // 11. uIsFading
      isFading ? 1.0 : 0.0,
      // 12. uFadeEdgeThickness
      (config.fadeConfig?.edgeThickness ?? 1.0),
      // 13. uEnableWaves
      config.particleConfig.enableWaves ? 1.0 : 0.0,
      // 14. uMaxWaveRadius
      config.particleConfig.maxWaveRadius,
      // 15. uMaxWaveCount
      config.particleConfig.maxWaveCount.toDouble(),
      // 16. uShapeArea
      config.particleConfig.areaFactor,
      // 17. uUseSprite
      config.particleConfig.shapePreset?.path != null ? 1.0 : 0.0,
    ];
  }

  static List<double> _baseUniforms(
    Rect rect,
    double time,
    double seed,
    Offset fadeOffset,
    bool isFading,
    double fadeRadius,
    SpoilerConfig config,
  ) {
    return [
      // 1. uResolution
      rect.width,
      rect.height,
      // 2. uTime
      time,
      // 3. uRect
      rect.left,
      rect.top,
      rect.width,
      rect.height,
      // 4. uSeed
      seed,
      // 5. uColor
      config.particleConfig.color.r,
      config.particleConfig.color.g,
      config.particleConfig.color.b,
      // 6. uDensity
      config.particleConfig.density,
      // 7. uSize
      config.particleConfig.maxParticleSize,
      // 8. uSpeed
      config.particleConfig.speed,
      // 9. uFadeCenter
      fadeOffset.dx,
      fadeOffset.dy,
      // 10. uFadeRadius
      fadeRadius,
      // 11. uIsFading
      isFading ? 1.0 : 0.0,
      // 12. uEdgeThickness
      (config.fadeConfig?.edgeThickness ?? 1.0) * 10.0,
    ];
  }

  factory ShaderConfig.particles() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/particles.frag',
        onGetShaderUniforms: _particleUniforms,
      );

  factory ShaderConfig.bokehCover() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/bokeh_cover.frag',
        onGetShaderUniforms: _baseUniforms,
      );

  /// Liquid Metal (CC0) warped FBM shader.
  factory ShaderConfig.liquidMetal() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/liquid_metal.frag',
        onGetShaderUniforms: _baseUniforms,
      );

  /// Glitch stripes with RGB splits.
  factory ShaderConfig.glitchStripes() => ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/glitch_stripes.frag',
        onGetShaderUniforms: (rect, time, seed, fadeOffset, isFading, fadeRadius, config) {
          return [
            rect.width,
            rect.height,
            time,
            rect.left,
            rect.top,
            rect.width,
            rect.height,
            seed,
            config.particleConfig.color.r,
            config.particleConfig.color.g,
            config.particleConfig.color.b,
            config.particleConfig.density,
            config.particleConfig.maxParticleSize,
            config.particleConfig.speed,
            fadeOffset.dx,
            fadeOffset.dy,
            fadeRadius,
            isFading ? 1.0 : 0.0,
            (config.fadeConfig?.edgeThickness ?? 1.0) * 10.0,
          ];
        },
      );

  /// Pixelated mosaic censor blocks.
  factory ShaderConfig.mosaicCensor() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/mosaic_censor.frag',
        onGetShaderUniforms: _baseUniforms,
      );

  /// Liquid Spectrum (HSV FBM) shader.
  factory ShaderConfig.liquidSpectrum() => const ShaderConfig(
        customShaderPath: 'packages/spoiler_widget/shaders/liquid_spectrum.frag',
        onGetShaderUniforms: _baseUniforms,
      );
}
