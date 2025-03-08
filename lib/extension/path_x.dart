import 'dart:math';

import 'package:flutter/rendering.dart';
import 'dart:ui';

/// An extension on the [Path] class to provide additional utility methods.
extension PathX on Path {
  /// Returns an iterable of subpaths that make up the current path.
  ///
  /// This generator function iterates over all the path metrics and extracts
  /// each subpath from the beginning to the full length of the metric.
  /// Useful for handling paths in segments.
  Iterable<Path> get subPaths sync* {
    for (final metric in computeMetrics()) {
      final subPath = metric.extractPath(0, metric.length);
      yield subPath;
    }
  }

  /// Returns a random point inside the path.
  ///
  /// This function continuously generates random points within the bounding box
  /// of the path until it finds one that is inside the path itself.
  ///
  /// **Note:** This method relies on a random search approach, which may be
  /// inefficient for complex or thin paths where finding an inside point takes
  /// multiple iterations.
  ///
  /// **Returns:** A randomly selected [Offset] that lies within the path.
  Offset getRandomPoint() {
    final random = Random();
    final boundingBox = getBounds();
    while (true) {
      final x = boundingBox.left + random.nextDouble() * boundingBox.width;
      final y = boundingBox.top + random.nextDouble() * boundingBox.height;
      final randomPoint = Offset(x, y);

      // Check if the point is inside the path
      if (contains(randomPoint)) {
        return randomPoint;
      }
    }
  }
}
