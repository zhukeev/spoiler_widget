import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class CircleImage {
  final ui.Image image;
  final ui.Color color;
  final double dimension;
  final double rasterDimension;

  const CircleImage({
    required this.image,
    required this.color,
    required this.dimension,
    required this.rasterDimension,
  });
}

@immutable
class FittedPathMetrics {
  final Rect bounds;
  final double maxDimension;
  final double centerX;
  final double centerY;

  const FittedPathMetrics({
    required this.bounds,
    required this.maxDimension,
    required this.centerX,
    required this.centerY,
  });

  bool get isDrawable => !bounds.isEmpty && maxDimension > 0.0;

  double scaleForDiameter(double targetDiameter) {
    final targetSize = math.max(targetDiameter - 1.0, 1.0);
    return isDrawable ? targetSize / maxDimension : 0.0;
  }

  Rect fittedBounds(ui.Offset center, double targetDiameter) {
    final scale = scaleForDiameter(targetDiameter);
    if (scale <= 0.0) {
      return Rect.zero;
    }

    final halfWidth = bounds.width * scale * 0.5;
    final halfHeight = bounds.height * scale * 0.5;
    return Rect.fromCenter(
      center: center,
      width: halfWidth * 2.0,
      height: halfHeight * 2.0,
    );
  }
}

FittedPathMetrics fittedPathMetricsFor(ui.Path path) {
  final bounds = path.getBounds();
  final maxDim = math.max(bounds.width, bounds.height);
  return FittedPathMetrics(
    bounds: bounds,
    maxDimension: maxDim,
    centerX: bounds.left + bounds.width * 0.5,
    centerY: bounds.top + bounds.height * 0.5,
  );
}

void drawFittedPath(
  ui.Canvas canvas,
  ui.Path path, {
  required ui.Offset center,
  required double targetDiameter,
  required ui.Paint paint,
  FittedPathMetrics? metrics,
}) {
  final fitted = metrics ?? fittedPathMetricsFor(path);
  if (!fitted.isDrawable) return;

  final scale = fitted.scaleForDiameter(targetDiameter);

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale, scale);
  canvas.translate(-fitted.centerX, -fitted.centerY);
  canvas.drawPath(path, paint);
  canvas.restore();
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
    double? rasterDiameter,
  }) {
    final safeRasterDiameter = rasterDiameter ?? diameter;
    final rasterSize = math.max(safeRasterDiameter.ceil(), 1);

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
      image: picture.toImageSync(rasterSize, rasterSize),
      color: color,
      dimension: diameter,
      rasterDimension: rasterSize.toDouble(),
    );
  }

  static void _drawCustomPath(
    ui.Canvas canvas,
    ui.Path path,
    ui.Offset center,
    double diameter,
    ui.Paint paint,
  ) {
    drawFittedPath(
      canvas,
      path,
      center: center,
      targetDiameter: diameter,
      paint: paint,
    );
  }
}
