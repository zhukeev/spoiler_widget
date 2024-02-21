import 'dart:math';

import 'package:flutter/rendering.dart';

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
    final (topLeft, topRight, bottomLeft, bottomRight) = divideRect();

    if (topLeft.containsOffset(offset)) {
      return bottomRight.bottomRight;
    } else if (topRight.containsOffset(offset)) {
      return bottomLeft.bottomLeft;
    } else if (bottomLeft.containsOffset(offset)) {
      return topRight.topRight;
    } else if (bottomRight.containsOffset(offset)) {
      return topLeft.topLeft;
    } else {
      return center;
    }
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

extension ListRectX on List<Rect> {
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
}
