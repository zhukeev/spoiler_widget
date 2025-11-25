import 'package:flutter/widgets.dart';

typedef PathBuilder = Path Function(Size size);

/// Generic path clipper.
class PathClipper extends CustomClipper<Path> {
  const PathClipper({required this.builder});

  final PathBuilder builder;

  @override
  Path getClip(Size size) => builder(size);

  @override
  bool shouldReclip(covariant PathClipper oldClipper) => true;
}
