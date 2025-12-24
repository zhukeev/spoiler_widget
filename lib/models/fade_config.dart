part of 'spoiler_configs.dart';

@immutable
class FadeConfig {
  final double padding;
  final double edgeThickness;

  const FadeConfig({
    required this.padding,
    required this.edgeThickness,
  });

  @override
  int get hashCode => Object.hash(padding, edgeThickness);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FadeConfig && padding == other.padding && edgeThickness == other.edgeThickness;
}
