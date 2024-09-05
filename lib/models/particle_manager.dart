import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spoiler_widget/extension/rect_x.dart';
import 'package:spoiler_widget/models/particle.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

class ParticleManager {
  final List<Particle> particles = [];
  final rng = Random();
  Path path = Path();
  late SpoilerConfiguration config;

  // ParticleManager(this.path, this.config) {
  //   _initializeParticles();
  // }

  void init(Path path, SpoilerConfiguration config) {
    this.path.reset();
    this.path.close();
    this.path = path;
    this.config = config;
    _initializeParticles();
  }

  Rect get bounds => path.getBounds();

  Offset getFarthestPoint(Offset center) => bounds.getFarthestPoint(center);

  List<Rect> _extractRectanglesFromPath() {
    final List<Rect> rectangles = [];
    final PathMetrics pathMetrics = path.computeMetrics();

    for (final PathMetric metric in pathMetrics) {
      final pathLength = metric.length;
      final List<Offset> points = [];

      for (double distance = 0.0; distance < pathLength; distance += pathLength / 4) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          points.add(tangent.position);
        }
      }

      // Check if the points form a rectangle
      if (points.length == 4) {
        final Rect rect = Rect.fromPoints(points[0], points[2]);
        rectangles.add(rect);
      }
    }

    return rectangles;
  }

  void _initializeParticles() {
    particles.clear();

    final rectangles = _extractRectanglesFromPath();

    debugPrint('rectangles: ${rectangles.firstOrNull}');
    debugPrint('rectangles: $bounds');

    for (int i = 0; i < rectangles.length; i++) {
      final rect = rectangles[i];
      final count = (rect.width + rect.height) * config.particleDensity;

      for (int j = 0; j < count; j++) {
        particles.add(_randomParticle(rect));
      }
    }
  }

  Particle _randomParticle(Rect rect) {
    final offset = rect.deflate(config.fadeRadius).randomOffset();
    return Particle(
      offset.dx,
      offset.dy,
      config.maxParticleSize,
      config.particleColor,
      rng.nextDouble(),
      config.speedOfParticles,
      rng.nextDouble() * 2 * pi,
      rect,
    );
  }

  void updateParticles() {
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      if (particle.life <= 0.1) {
        particles[i] = _randomParticle(particle.rect);
      } else {
        particles[i] = particle.moveToRandomAngle();
      }
    }
  }
}
