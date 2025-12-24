part of 'spoiler_configs.dart';

@immutable
class ParticlePathPreset {
  final Path path;
  final double? areaFactor;

  const ParticlePathPreset({
    required this.path,
    this.areaFactor,
  });

  factory ParticlePathPreset.custom(
    Path path, {
    double? areaFactor,
  }) =>
      ParticlePathPreset(path: path, areaFactor: areaFactor);

  static final ParticlePathPreset circle = ParticlePathPreset(
    path: Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 1.0)),
    areaFactor: 1.0,
  );

  static final ParticlePathPreset star = ParticlePathPreset(
    path: buildStarPath(Offset.zero, 1.0, 5, 0.45),
    areaFactor: 0.421,
  );

  static final ParticlePathPreset snowflake = ParticlePathPreset(
    path: buildStarPath(Offset.zero, 1.0, 6, 0.25),
    areaFactor: 0.239,
  );

  static Path buildStarPath(
    Offset center,
    double outerRadius,
    int points,
    double innerRatio,
  ) {
    final innerRadius = outerRadius * innerRatio;
    final angleStep = math.pi / points;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final radius = (i % 2 == 0) ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + angleStep * i;
      final dx = center.dx + math.cos(angle) * radius;
      final dy = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    return path;
  }
}
