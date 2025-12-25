part of 'spoiler_configs.dart';

/// Configuration for spoiler fade behavior.
@immutable
class FadeConfig {
  /// Padding used to expand the reveal/cover area.
  final double padding;

  /// Thickness of the fade edge band.
  final double edgeThickness;

  const FadeConfig({
    required this.padding,
    required this.edgeThickness,
  });

  @override
  int get hashCode => Object.hash(padding, edgeThickness);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FadeConfig &&
          padding == other.padding &&
          edgeThickness == other.edgeThickness;
}
