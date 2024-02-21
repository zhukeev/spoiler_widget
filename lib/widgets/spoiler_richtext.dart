import 'package:flutter/rendering.dart'
    show DiagnosticPropertiesBuilder, DiagnosticsProperty, TextSelection;
import 'package:flutter/widgets.dart'
    show BuildContext, Directionality, RichText, ValueSetter;
import 'package:spoiler_widget/models/string_details.dart';
import 'package:spoiler_widget/widgets/spoiler_paragraph.dart';

class SpoilerRichText extends RichText {
  final bool initialized;
  final ValueSetter<StringDetails> onBoundariesCalculated;
  final PaintCallback? onPaint;
  final TextSelection? selection;

  SpoilerRichText({
    required this.onBoundariesCalculated,
    required this.initialized,
    this.onPaint,
    this.selection,
    super.key,
    required super.text,
  });

  @override
  SpoilerParagraph createRenderObject(BuildContext context) {
    return SpoilerParagraph(
      text,
      onPaint: onPaint,
      selection: selection,
      onBoundariesCalculated: onBoundariesCalculated,
      initialized: initialized,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('initialized', initialized));
    properties.add(DiagnosticsProperty<ValueSetter<StringDetails>>(
        'onBoundariesCalculated', onBoundariesCalculated));
    properties.add(DiagnosticsProperty<PaintCallback?>('onPaint', onPaint));
  }
}
