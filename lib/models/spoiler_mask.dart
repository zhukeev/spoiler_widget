part of 'spoiler_configs.dart';

/// Configuration for applying a mask to the spoiler effect.
///
/// A mask defines a specific area where the spoiler effect is applied
/// using a [Path] and a [PathOperation] to determine how the mask interacts
/// with the spoiler area.
class SpoilerMask {
  /// The shape or area used as the mask.
  final Path maskPath;

  /// The operation defining how the mask interacts with the spoiler content.
  final PathOperation maskOperation;

  /// The offset to shift the mask position.
  ///
  /// This allows dynamic positioning of the mask relative to its original placement.
  final Offset offset;

  /// Creates a mask configuration with the given path, operation, and optional offset.
  ///
  /// The [offset] parameter defaults to `Offset.zero`, meaning no shift in position.
  SpoilerMask({
    required this.maskPath,
    required this.maskOperation,
    this.offset = Offset.zero,
  });

  /// Builds a star-shaped [Path] helper for mask creation.
  static Path buildStarPath(
    Offset center,
    double outerRadius,
    int points,
    double innerRatio,
  ) {
    return ParticlePathPreset.buildStarPath(
      center,
      outerRadius,
      points,
      innerRatio,
    );
  }
}
