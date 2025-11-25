import 'package:flutter/widgets.dart';

/// Recursively hides all Text / RichText widgets in the subtree by wrapping
/// them into Opacity(0.0), while preserving layout and keeping RenderParagraphs
/// alive for measurement.
///
/// For supported container widgets, it rebuilds them with transformed children.
/// For unknown widgets it returns them as-is, so any text inside unsupported
/// containers will remain visible (not spoilered).
Widget hideTextInSubtree(Widget widget) {
  Widget? transformChild(Widget? child) => child == null ? null : hideTextInSubtree(child);

  List<Widget> transformChildren(List<Widget> children) => List<Widget>.generate(
        children.length,
        (i) => hideTextInSubtree(children[i]),
        growable: false,
      );

  return switch (widget) {
    // ----------------------------------------------------------------------
    // TEXT WITH DATA
    // ----------------------------------------------------------------------

    Text(
      :final key,
      data: var textData, // extracts `data` field
      :final style,
      :final textAlign,
      :final textDirection,
      :final locale,
      :final softWrap,
      :final overflow,
      :final textScaleFactor,
      :final maxLines,
      :final semanticsLabel,
      :final textWidthBasis,
      :final textHeightBehavior,
      :final strutStyle,
    )
        when textData != null =>
      Opacity(
        key: key,
        opacity: 0.0,
        child: Text(
          textData,
          style: style,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          strutStyle: strutStyle,
        ),
      ),

    // ----------------------------------------------------------------------
    // TEXT WITH TEXTSPAN
    // ----------------------------------------------------------------------

    Text(
      :final key,
      textSpan: var span,
      :final style,
      :final textAlign,
      :final textDirection,
      :final locale,
      :final softWrap,
      :final overflow,
      :final textScaleFactor,
      :final maxLines,
      :final semanticsLabel,
      :final textWidthBasis,
      :final textHeightBehavior,
      :final strutStyle,
    )
        when span != null =>
      Opacity(
        key: key,
        opacity: 0.0,
        child: Text.rich(
          span,
          style: style,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          strutStyle: strutStyle,
        ),
      ),

    // ----------------------------------------------------------------------
    // RICHTEXT
    // ----------------------------------------------------------------------

    RichText(
      :final key,
      :final text,
      :final textAlign,
      :final textDirection,
      :final softWrap,
      :final overflow,
      :final textScaler,
      :final maxLines,
      :final locale,
      :final strutStyle,
      :final textWidthBasis,
      :final textHeightBehavior,
      :final selectionRegistrar,
      :final selectionColor,
    ) =>
      Opacity(
        key: key,
        opacity: 0.0,
        child: RichText(
          text: text,
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          locale: locale,
          strutStyle: strutStyle,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionRegistrar: selectionRegistrar,
          selectionColor: selectionColor,
        ),
      ),

    // ----------------------------------------------------------------------
    // MULTI-CHILD WIDGETS
    // ----------------------------------------------------------------------

    Flex(
      :final key,
      :final direction,
      :final mainAxisAlignment,
      :final mainAxisSize,
      :final crossAxisAlignment,
      :final textDirection,
      :final verticalDirection,
      :final textBaseline,
      children: var children,
    ) =>
      Flex(
        key: key,
        direction: direction,
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        children: transformChildren(children),
      ),
    Stack(
      :final key,
      :final alignment,
      :final textDirection,
      :final fit,
      :final clipBehavior,
      children: var children,
    ) =>
      Stack(
        key: key,
        alignment: alignment,
        textDirection: textDirection,
        fit: fit,
        clipBehavior: clipBehavior,
        children: transformChildren(children),
      ),

    // ----------------------------------------------------------------------
    // SINGLE-CHILD WIDGETS
    // ----------------------------------------------------------------------

    Padding(:final key, :final padding, child: var child) => Padding(
        key: key,
        padding: padding,
        child: transformChild(child),
      ),
    Align(
      :final key,
      :final alignment,
      :final widthFactor,
      :final heightFactor,
      child: var child,
    ) =>
      Align(
        key: key,
        alignment: alignment,
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        child: transformChild(child),
      ),
    SizedBox(:final key, :final width, :final height, child: var child) => SizedBox(
        key: key,
        width: width,
        height: height,
        child: transformChild(child),
      ),
    Container(
      :final key,
      :final alignment,
      :final padding,
      :final color,
      :final decoration,
      :final foregroundDecoration,
      :final constraints,
      :final margin,
      :final transform,
      :final transformAlignment,
      :final clipBehavior,
      child: var child,
    ) =>
      Container(
        key: key,
        alignment: alignment,
        padding: padding,
        color: color,
        decoration: decoration,
        foregroundDecoration: foregroundDecoration,
        constraints: constraints,
        margin: margin,
        transform: transform,
        transformAlignment: transformAlignment,
        clipBehavior: clipBehavior,
        child: transformChild(child),
      ),

    // ----------------------------------------------------------------------
    // FLEX PARENT-DATA
    // ----------------------------------------------------------------------
    Flexible(:final key, :final flex, :final fit, child: var child) => Flexible(
        key: key,
        flex: flex,
        fit: fit,
        child: hideTextInSubtree(child),
      ),

    // ----------------------------------------------------------------------
    // FALLBACK
    // ----------------------------------------------------------------------

    _ => widget,
  };
}
