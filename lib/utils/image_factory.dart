import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

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
    ui.Path? shapePath,
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

    if (shapePath != null) {
      _drawCustomPath(canvas, shapePath, center, diameter, paint);
    } else {
      canvas.drawCircle(center, radius, paint);
    }

    // End recording and convert it to an image
    final picture = recorder.endRecording();
    return CircleImage(
      image: picture.toImageSync(diameter.toInt(), diameter.toInt()),
      color: color,
      dimension: diameter,
    );
  }

  static void _drawCustomPath(
    ui.Canvas canvas,
    ui.Path path,
    ui.Offset center,
    double diameter,
    ui.Paint paint,
  ) {
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;
    final maxDim = math.max(bounds.width, bounds.height);
    if (maxDim <= 0.0) return;

    final targetSize = math.max(diameter - 1.0, 1.0);
    final scale = targetSize / maxDim;
    final cx = bounds.left + bounds.width * 0.5;
    final cy = bounds.top + bounds.height * 0.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.translate(-cx, -cy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}
