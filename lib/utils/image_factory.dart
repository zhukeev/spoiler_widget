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
  }) {
    // Create a PictureRecorder to record drawing commands
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Prepare the paint with the given color
    final paint = ui.Paint()..color = color;

    // Calculate the radius
    final radius = diameter / 2;

    // Draw a circle on the canvas
    canvas.drawCircle(ui.Offset.zero, radius, paint);

    // End recording and convert it to an image
    final picture = recorder.endRecording();
    return CircleImage(
      image: picture.toImageSync(diameter.toInt(), diameter.toInt()),
      color: color,
      dimension: diameter,
    );
  }
}
