import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

@immutable
class CircleImage {
  final ui.Image image;
  final ui.Color color;
  final double dimension;

  const CircleImage({
    required this.image,
    required this.color,
    required this.dimension,
  });
}

/// A factory class for creating circular images using Flutter's low-level
/// [dart:ui] drawing APIs.
class CircleImageFactory {
  /// Creates a circular [ui.Image] of the given [diameter] and [color].
  ///
  /// The image is drawn using a [ui.PictureRecorder] and [ui.Canvas].
  /// The resulting [ui.Image] has a width and height equal to [diameter].
  ///
  /// **Parameters:**
  /// - [diameter]: The diameter of the circle in pixels.
  /// - [color]: The fill color of the circle.
  ///
  /// **Returns:**
  /// A [ui.Image] containing a circle of the specified size and color.
  ///
  /// **Example Usage:**
  /// ```dart
  /// final image = CircleImageFactory.create(
  ///   diameter: 100.0,
  ///   color: ui.Color(0xFFFF0000), // Red color
  /// );
  /// ```
  static CircleImage create({
    required double diameter,
    required ui.Color color,
    ParticleShape shape = ParticleShape.circle,
  }) {
    // Create a PictureRecorder to record drawing commands
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0x00000000), ui.BlendMode.clear);

    // Prepare the paint with the given color
    final paint = ui.Paint()..color = color;

    // Calculate the radius
    final radius = diameter / 2;
    final center = ui.Offset(radius, radius);

    switch (shape) {
      case ParticleShape.circle:
        canvas.drawCircle(center, radius, paint);
        break;
      case ParticleShape.star:
        canvas.drawPath(_buildStarPath(center, radius, 5, 0.45), paint);
        break;
      case ParticleShape.snowflake:
        canvas.drawPath(_buildStarPath(center, radius, 6, 0.25), paint);
        break;
    }

    // End recording and convert it to an image
    final picture = recorder.endRecording();
    return CircleImage(
      image: picture.toImageSync(diameter.toInt(), diameter.toInt()),
      color: color,
      dimension: diameter,
    );
  }

  static ui.Path _buildStarPath(
    ui.Offset center,
    double outerRadius,
    int points,
    double innerRatio,
  ) {
    final innerRadius = outerRadius * innerRatio;
    final angleStep = math.pi / points;
    final path = ui.Path();

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
