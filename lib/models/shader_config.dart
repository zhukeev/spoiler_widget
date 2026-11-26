part of 'spoiler_configs.dart';

/// Generates the list of float uniforms passed to a fragment shader.
typedef ShaderCallback =
    List<double> Function(
      Rect rect,
      double time,
      double seed,
      Offset fadeCenter,
      bool isFading,
      double fadeRadius,
      SpoilerConfig config,
    );

/// Describes a fragment shader and how to build its uniform values.
@immutable
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

  /// Shared uniform prefix: uResolution, uTime, uRect, uSeed, uColor.
  /// Every built-in shader declares these first, in this order.
  static List<double> _coreUniforms(
    Rect rect,
    double time,
    double seed,
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
    ];
  }

  /// Shared suffix: uDensity, uSize, uSpeed, uFadeCenter, uFadeRadius,
  /// uIsFading, uEdgeThickness — the tail shared by all built-in shaders.
  static List<double> _tailUniforms(
    Offset fadeOffset,
    bool isFading,
    double fadeRadius,
    SpoilerConfig config, {
    required bool scaleEdgeThickness,
    required bool clampDensity,
  }) {
    return [
      // 6. uDensity
      clampDensity
          ? config.particleConfig.density.clamp(0.0, 1.0)
          : config.particleConfig.density,
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
      scaleEdgeThickness
          ? (config.fadeConfig?.edgeThickness ?? 1.0) * 10.0
          : (config.fadeConfig?.edgeThickness ?? 1.0),
    ];
  }

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
      ..._coreUniforms(rect, time, seed, config),
      ..._tailUniforms(
        fadeOffset,
        isFading,
        fadeRadius,
        config,
        scaleEdgeThickness: false,
        clampDensity: true,
      ),
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
      ..._coreUniforms(rect, time, seed, config),
      ..._tailUniforms(
        fadeOffset,
        isFading,
        fadeRadius,
        config,
        scaleEdgeThickness: true,
        clampDensity: false,
      ),
    ];
  }

  /// Default particle shader with sprite support.
  ///
  /// [customShaderPath] overrides the bundled asset path — useful for a
  /// modified copy of `particles.frag` (e.g. a sampler-free variant where
  /// runtime-effect samplers are unsupported, such as the iOS simulator).
  factory ShaderConfig.particles({String? customShaderPath}) => ShaderConfig(
    customShaderPath:
        customShaderPath ?? 'packages/spoiler_widget/shaders/particles.frag',
    onGetShaderUniforms: _particleUniforms,
  );

  /// Soft bokeh-style blur cover shader.
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
  factory ShaderConfig.glitchStripes() => const ShaderConfig(
    customShaderPath: 'packages/spoiler_widget/shaders/glitch_stripes.frag',
    onGetShaderUniforms: _baseUniforms,
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

  @override
  int get hashCode => Object.hash(customShaderPath, onGetShaderUniforms);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShaderConfig &&
          customShaderPath == other.customShaderPath &&
          onGetShaderUniforms == other.onGetShaderUniforms;
}
