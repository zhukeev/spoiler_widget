import 'package:flutter/rendering.dart';

/// Builds a stable signature for a [Path] to detect geometry changes.
///
/// Combines overall bounds, number of subpaths, and metric lengths.
String pathSignature(Path path) {
  final bounds = path.getBounds();
  final buffer = StringBuffer()
    ..write(bounds.left)
    ..write(',')
    ..write(bounds.top)
    ..write(',')
    ..write(bounds.right)
    ..write(',')
    ..write(bounds.bottom)
    ..write('|');

  int metricsCount = 0;
  for (final metric in path.computeMetrics()) {
    metricsCount++;
    buffer
      ..write(metric.length)
      ..write(';');
  }
  buffer.write('#$metricsCount');

  return buffer.toString();
}
