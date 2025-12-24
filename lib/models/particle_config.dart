part of 'spoiler_configs.dart';

final Expando<double> _pathAreaCache = Expando<double>('particleShapeArea');

double _estimatePathAreaFactor(Path path, {int samples = 48}) {
  final cached = _pathAreaCache[path];
  if (cached != null) return cached;

  final bounds = path.getBounds();
  if (bounds.isEmpty) {
    _pathAreaCache[path] = 0.0;
    return 0.0;
  }

  final maxDim = math.max(bounds.width, bounds.height);
  if (maxDim <= 0.0) {
    _pathAreaCache[path] = 0.0;
    return 0.0;
  }

  final squareLeft = bounds.center.dx - maxDim * 0.5;
  final squareTop = bounds.center.dy - maxDim * 0.5;
  int inside = 0;
  final total = samples * samples;
  for (int y = 0; y < samples; y++) {
    final fy = (y + 0.5) / samples;
    for (int x = 0; x < samples; x++) {
      final fx = (x + 0.5) / samples;
      final dx = squareLeft + fx * maxDim;
      final dy = squareTop + fy * maxDim;
      if (path.contains(Offset(dx, dy))) {
        inside++;
      }
    }
  }

  final fillFraction = inside / total;
  final areaFactor = fillFraction * (4.0 / math.pi);
  _pathAreaCache[path] = areaFactor;
  return areaFactor;
}

@immutable
class ParticleConfig {
  /// Fraction of area covered by particles (0..1 => 0%..100%).
  final double density;
  final double speed;
  final Color color;
  final double maxParticleSize;
  final ParticlePathPreset? shapePreset;
  final bool enableWaves;
  final double maxWaveRadius;
  final int maxWaveCount;

  const ParticleConfig({
    required this.density,
    required this.speed,
    required this.color,
    required this.maxParticleSize,
    this.shapePreset,
    this.enableWaves = false,
    this.maxWaveRadius = 0.0,
    this.maxWaveCount = 3,
  });

  factory ParticleConfig.defaultConfig() => ParticleConfig(
        density: 0.1,
        speed: 0.2,
        color: Colors.white,
        maxParticleSize: 1.0,
        shapePreset: ParticlePathPreset.circle,
      );

  double get areaFactor {
    if (shapePreset == null) return 1.0;
    final presetArea = shapePreset!.areaFactor;
    return presetArea ?? _estimatePathAreaFactor(shapePreset!.path);
  }

  @override
  int get hashCode => Object.hash(
        density,
        speed,
        color,
        maxParticleSize,
        shapePreset,
        enableWaves,
        maxWaveRadius,
        maxWaveCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleConfig &&
          density == other.density &&
          speed == other.speed &&
          color == other.color &&
          maxParticleSize == other.maxParticleSize &&
          shapePreset == other.shapePreset &&
          enableWaves == other.enableWaves &&
          maxWaveRadius == other.maxWaveRadius &&
          maxWaveCount == other.maxWaveCount;
}
