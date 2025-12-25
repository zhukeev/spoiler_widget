import 'dart:math';

import 'package:flutter/rendering.dart';

/// Geometry helpers for [Rect].
extension RectX on Rect {
  /// Check if {offset} is inside the rectangle
  ///
  /// Example:
  /// ```dart
  /// final rect = Rect.fromLTWH(0, 0, 100, 100);
  /// final offset = Offset(50, 50);
  ///
  /// rect.containsOffset(offset); // true
  /// ```
  ///
  bool containsOffset(Offset offset) {
    return bottom >= offset.dy &&
        top <= offset.dy &&
        left <= offset.dx &&
        right >= offset.dx;
  }

  /// Splits the rect into four equal quadrants.
  (Rect, Rect, Rect, Rect) divideRect() {
    final halfWidth = width / 2;
    final halfHeight = height / 2;

    final topLeft =
        Rect.fromLTRB(left, top, left + halfWidth, top + halfHeight);
    final topRight =
        Rect.fromLTRB(left + halfWidth, top, right, top + halfHeight);
    final bottomLeft =
        Rect.fromLTRB(left, top + halfHeight, left + halfWidth, bottom);
    final bottomRight =
        Rect.fromLTRB(left + halfWidth, top + halfHeight, right, bottom);

    return (topLeft, topRight, bottomLeft, bottomRight);
  }

  /// Get the farthest corner from {offset}
  Offset getFarthestPoint(Offset offset) {
    final corners = [
      topLeft,
      topRight,
      bottomLeft,
      bottomRight,
    ];

    var farthest = corners.first;
    var maxDistance = (farthest - offset).distanceSquared;

    for (final corner in corners.skip(1)) {
      final distance = (corner - offset).distanceSquared;
      if (distance > maxDistance) {
        maxDistance = distance;
        farthest = corner;
      }
    }

    return farthest;
  }

  /// Get the nearest corner from {offset}
  Offset getNearestPoint(Offset offset) {
    // Clamp the x-coordinate of the offset within the rect's horizontal boundaries
    final nearestX = offset.dx.clamp(left, right);

    // Clamp the y-coordinate of the offset within the rect's vertical boundaries
    final nearestY = offset.dy.clamp(top, bottom);

    // Return the nearest corner
    return Offset(nearestX, nearestY);
  }

  /// Get random offset inside the rectangle
  Offset randomOffset() {
    final maxX = (width + left);
    final minX = left;
    final maxY = (height + top);
    final minY = top;

    return Offset(
      minX + (Random().nextDouble() * (maxX - minX)),
      minY + (Random().nextDouble() * (maxY - minY)),
    );
  }
}

/// Collection helpers for lists of [Rect].
extension ListRectX on List<Rect> {
  /// Returns a bounding rect covering all items.
  Rect getBounds() {
    if (isEmpty) {
      return Rect.zero;
    }

    var left = first.left;
    var top = first.top;
    var right = first.right;
    var bottom = first.bottom;

    for (final rect in this) {
      if (rect.left < left) {
        left = rect.left;
      }

      if (rect.top < top) {
        top = rect.top;
      }

      if (rect.right > right) {
        right = rect.right;
      }

      if (rect.bottom > bottom) {
        bottom = rect.bottom;
      }
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Merges adjacent rects that touch horizontally.
  List<Rect> mergeRects() {
    final merged = <Rect>[];

    for (final rect in this) {
      if (merged.isEmpty) {
        merged.add(rect);
      } else {
        final last = merged.last;
        if (rect.left == last.right) {
          merged[merged.length - 1] = last.expandToInclude(rect);
        } else {
          merged.add(rect);
        }
      }
    }

    return merged;
  }
}
