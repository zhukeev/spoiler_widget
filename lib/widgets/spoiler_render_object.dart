// ignore_for_file: override_on_non_overriding_member

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'canvas_callback_painter.dart';
import '../utils/spoiler_path_builder.dart';
import '../utils/text_layout_client.dart';

/// Render object widget that paints a child while exposing hook points
/// for clipping, particle painting, and rectangle collection.
class SpoilerRenderObjectWidget extends SingleChildRenderObjectWidget {
  const SpoilerRenderObjectWidget({
    super.key,
    required super.child,
    this.onPaint,
    this.onAfterPaint,
    this.onClipPath,
    this.onInit,
    this.imageFilter,
    this.textSelection,
    this.enableOverlay = false,
  });

  final PaintCallback? onPaint;
  final PaintCallback? onAfterPaint;
  final Path Function(Size size)? onClipPath;
  final ValueChanged<List<Rect>>? onInit;
  final ui.ImageFilter? imageFilter;
  final bool enableOverlay;
  final TextSelection? textSelection;

  @override
  RenderSpoiler createRenderObject(BuildContext context) {
    return RenderSpoiler(
      onPaint: onPaint,
      onAfterPaint: onAfterPaint,
      onClipPath: onClipPath,
      onInit: onInit,
      imageFilter: imageFilter,
      enableOverlay: enableOverlay,
      textSelection: textSelection,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderSpoiler renderObject) {
    renderObject
      ..onPaint = onPaint
      ..onAfterPaint = onAfterPaint
      ..onClipPath = onClipPath
      ..onInit = onInit
      ..imageFilter = imageFilter
      ..textSelection = textSelection
      ..enableOverlay = enableOverlay;
  }
}

/// RenderBox that can paint overlay effects (before/after child), apply
/// an optional clip, and report text rects for spoiler effects.
class RenderSpoiler extends RenderProxyBox {
  RenderSpoiler({
    PaintCallback? onPaint,
    PaintCallback? onAfterPaint,
    Path Function(Size size)? onClipPath,
    ValueChanged<List<Rect>>? onInit,
    ui.ImageFilter? imageFilter,
    TextSelection? textSelection,
    bool enableOverlay = false,
    RenderBox? child,
  })  : _onPaint = onPaint,
        _onAfterPaint = onAfterPaint,
        _onClipPath = onClipPath,
        _onInit = onInit,
        _imageFilter = imageFilter,
        _enableOverlay = enableOverlay,
        super(child);

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestSelf(Offset position) => true;

  final Set<ViewportOffset> _listenedOffsets = <ViewportOffset>{};

  List<RenderEditable> _findRenderEditables(RenderObject root, {Set<ViewportOffset>? offsets}) {
    final out = <RenderEditable>[];

    void visit(RenderObject node) {
      if (node is RenderEditable) {
        out.add(node);
        if (offsets != null) offsets.add(node.offset);
      }
      node.visitChildren(visit);
    }

    visit(root);
    return out;
  }

  PaintCallback? _onPaint;
  set onPaint(PaintCallback? value) {
    if (_onPaint != value) {
      _onPaint = value;
      markNeedsPaint();
    }
  }

  PaintCallback? _onAfterPaint;
  set onAfterPaint(PaintCallback? value) {
    if (_onAfterPaint != value) {
      _onAfterPaint = value;
      markNeedsPaint();
    }
  }

  Path Function(Size size)? _onClipPath;
  set onClipPath(Path Function(Size size)? value) {
    if (_onClipPath != value) {
      _onClipPath = value;
      markNeedsPaint();
    }
  }

  ValueChanged<List<Rect>>? _onInit;
  set onInit(ValueChanged<List<Rect>>? value) {
    if (_onInit != value) {
      _onInit = value;
      markNeedsPaint();
    }
  }

  ui.ImageFilter? _imageFilter;
  set imageFilter(ui.ImageFilter? value) {
    if (_imageFilter != value) {
      _imageFilter = value;
      markNeedsPaint();
    }
  }

  TextSelection? _textSelection;
  set textSelection(TextSelection? value) {
    if (_textSelection != value) {
      _textSelection = value;
      _rectsDirty = true;
      if (value == null) {
        _lastSelection = null;
        _cachedSelectionRects = const [];
        _lastInitRectsHash = 0;
      }
      markNeedsPaint();
    }
  }

  bool _enableOverlay;
  set enableOverlay(bool value) {
    if (_enableOverlay != value) {
      _enableOverlay = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    _rectsDirty = true;
    _cachedSelectionRects = const [];
  }

  bool _rectsDirty = true;
  int _lastInitRectsHash = 0;
  TextSelection? _lastSelection;
  List<Rect> _cachedSelectionRects = const [];

  @override
  void paint(PaintingContext context, Offset offset) {
    final visitedOffsets = <ViewportOffset>{};
    final childRo = child;
    final editables =
        childRo != null ? _findRenderEditables(childRo, offsets: visitedOffsets) : const <RenderEditable>[];
    final selection = _textSelection;

    if (selection != null) {
      final shouldRecalculate = _rectsDirty || _lastSelection != selection || _cachedSelectionRects.isEmpty;
      if (shouldRecalculate) {
        if (editables.isNotEmpty) {
          final collected = <Rect>[];

          for (final re in editables) {
            final geom = _buildEditableGeometry(re, selection);
            if (geom == null) continue;

            final Matrix4 m = re.getTransformTo(this);
            final Offset paintOffset = _editablePaintOffset(re);
            collected.addAll(
              geom.rects
                  .map((r) => _normalizeEditableRect(r.shift(paintOffset), re))
                  .map((r) => MatrixUtils.transformRect(m, r)),
            );
          }

          if (collected.isNotEmpty) {
            _cachedSelectionRects = collected;
            final h = _hashRects(collected);
            if (h != _lastInitRectsHash) {
              _lastInitRectsHash = h;
              _onInit?.call(collected);
            }
          }
        }
        _lastSelection = selection;
      }

      _rectsDirty = false;
    }

    final clipPath = _normalizeClipPath(_onClipPath?.call(size));

    if (_enableOverlay) {
      super.paint(context, offset);

      if (clipPath == null && _onPaint == null && _onAfterPaint == null && _imageFilter == null) {
        _syncEditableOffsets(visitedOffsets);
        return;
      }

      if (clipPath != null) {
        context.pushClipPath(needsCompositing, offset, paintBounds.shift(offset), clipPath, (c, o) {
          _paintOverlayContent(c, o);
        });
      } else {
        _paintOverlayContent(context, offset);
      }
      _syncEditableOffsets(visitedOffsets);
      return;
    }

    void paintSpoilerLayer(PaintingContext layerContext, Offset layerOffset) {
      final spoilerContext = layerContext is SpoilerPaintingContext
          ? layerContext
          : SpoilerPaintingContext(
              layer: layer!,
              estimatedBounds: paintBounds.shift(layerOffset),
              calculateRects: _rectsDirty,
            );

      Path? particleClipPath;
      if (clipPath != null) {
        particleClipPath = Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          clipPath,
        );
      }

      if (_onPaint != null) {
        if (particleClipPath != null) {
          spoilerContext.pushClipPath(needsCompositing, layerOffset, paintBounds.shift(layerOffset), particleClipPath,
              (c, o) {
            _drawParticles(c, o, _onPaint);
          });
        } else {
          _drawParticles(spoilerContext, layerOffset, _onPaint);
        }
      }

      if (clipPath != null) {
        spoilerContext.pushClipPath(needsCompositing, layerOffset, paintBounds.shift(layerOffset), clipPath, (c, o) {
          _paintChildWithFilter(c, o);
        });
      } else {
        _paintChildWithFilter(spoilerContext, layerOffset);
      }

      if (_onAfterPaint != null) {
        if (particleClipPath != null) {
          spoilerContext.pushClipPath(needsCompositing, layerOffset, paintBounds.shift(layerOffset), particleClipPath,
              (c, o) {
            _drawParticles(c, o, _onAfterPaint);
          });
        } else {
          _drawParticles(spoilerContext, layerOffset, _onAfterPaint);
        }
      }
    }

    final rootSpoilerContext = SpoilerPaintingContext(
      layer: layer!,
      estimatedBounds: paintBounds.shift(offset),
      calculateRects: _rectsDirty,
    );

    paintSpoilerLayer(rootSpoilerContext, offset);

    // ignore: invalid_use_of_protected_member
    rootSpoilerContext.stopRecordingIfNeeded();

    if (_rectsDirty && _textSelection == null) {
      _onInit?.call(rootSpoilerContext.spoilerRects);
      _rectsDirty = false;
    }
    _syncEditableOffsets(visitedOffsets);
  }

  void _paintOverlayContent(PaintingContext context, Offset offset) {
    _drawParticles(context, offset, _onPaint);

    if (_imageFilter != null) {
      context.pushLayer(BackdropFilterLayer(filter: _imageFilter!), (childContext, childOffset) {
        _drawParticles(childContext, childOffset, _onAfterPaint);
      }, offset);
    } else {
      _drawParticles(context, offset, _onAfterPaint);
    }
  }

  void _drawParticles(PaintingContext currentContext, Offset currentOffset, PaintCallback? callback) {
    if (callback != null) {
      final canvas = currentContext.canvas;
      canvas.save();
      canvas.translate(currentOffset.dx, currentOffset.dy);
      callback(canvas, size);
      canvas.restore();
    }
  }

  int _hashRects(List<Rect> rects) {
    return Object.hashAll(
      rects.expand((r) => <double>[r.left, r.top, r.right, r.bottom]),
    );
  }

  void _paintChildWithFilter(PaintingContext context, Offset offset) {
    if (_imageFilter != null) {
      context.pushLayer(
        ImageFilterLayer(imageFilter: _imageFilter!),
        super.paint,
        offset,
      );
    } else {
      super.paint(context, offset);
    }
  }

  Path? _normalizeClipPath(Path? path) {
    if (path == null) return null;
    final metrics = path.computeMetrics();
    return metrics.isEmpty ? null : path;
  }

  void _syncEditableOffsets(Set<ViewportOffset> visited) {
    for (final offset in visited) {
      if (_listenedOffsets.add(offset)) {
        offset.addListener(_onEditableOffsetChanged);
      }
    }

    final stale = _listenedOffsets.difference(visited).toList(growable: false);
    for (final offset in stale) {
      offset.removeListener(_onEditableOffsetChanged);
    }
    _listenedOffsets.removeAll(stale);
  }

  void _onEditableOffsetChanged() {
    _rectsDirty = true;
    _cachedSelectionRects = const [];
    markNeedsPaint();
  }

  @override
  void detach() {
    for (final offset in _listenedOffsets) {
      offset.removeListener(_onEditableOffsetChanged);
    }
    _listenedOffsets.clear();
    super.detach();
  }

  SpoilerGeometry? _buildEditableGeometry(RenderEditable editable, TextSelection selection) {
    final text = editable.plainText;
    if (text.isEmpty) return null;
    return buildSpoilerGeometry(
      layout: RenderEditableLayoutClient(editable),
      text: text,
      selection: selection,
      skipWhitespace: true,
    );
  }
}

/// Painting context that captures text bounding rects while delegating
/// normal painting to Flutter's pipeline.
class SpoilerPaintingContext extends PaintingContext {
  SpoilerPaintingContext({
    required ContainerLayer layer,
    required Rect estimatedBounds,
    required this.calculateRects,
  }) : super(layer, estimatedBounds);

  final bool calculateRects;
  final List<Rect> spoilerRects = [];
  String? currentText;

  @override
  ui.Canvas get canvas => SpoilerCanvas(super.canvas, this);

  @override
  void paintChild(RenderObject child, Offset offset) {
    if (child is RenderParagraph && calculateRects) {
      currentText = child.text.toPlainText();
    } else if (child is RenderEditable) {
      currentText = child.plainText;
      if (currentText != null && currentText!.isNotEmpty) {
        final boxes = child.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: currentText!.length),
        );
        final paintOffset = _editablePaintOffset(child);
        for (final b in boxes) {
          spoilerRects.add(_normalizeEditableRect(b.toRect().shift(offset + paintOffset), child));
        }
      }
    }
    super.paintChild(child, offset);
    currentText = null;
  }

  @override
  PaintingContext createChildContext(ContainerLayer childLayer, ui.Rect bounds) {
    return _ChildSpoilerPaintingContext(
      layer: childLayer,
      estimatedBounds: bounds,
      rootRects: spoilerRects,
      calculateRects: calculateRects,
    );
  }
}

/// Child context that appends rects into the root's collection so nested
/// children contribute to a single list.
class _ChildSpoilerPaintingContext extends SpoilerPaintingContext {
  _ChildSpoilerPaintingContext({
    required super.layer,
    required super.estimatedBounds,
    required this.rootRects,
    required super.calculateRects,
  });

  final List<Rect> rootRects;

  @override
  List<Rect> get spoilerRects => rootRects;
}

Offset _editablePaintOffset(RenderEditable editable) {
  // Use a stable reference: first glyph box vs caret at offset 0.
  try {
    final text = editable.plainText;
    if (text.isNotEmpty) {
      final caret = editable.getLocalRectForCaret(
        const TextPosition(offset: 0),
      );
      final boxes = editable.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      );
      if (boxes.isNotEmpty) {
        return caret.topLeft - boxes.first.toRect().topLeft;
      }
    }
  } catch (_) {
    // ignore and fall back
  }

  // Fallback to scroll-based approximation if caret metrics aren't available.
  final pixels = editable.offset.pixels;
  if (pixels == 0) return Offset.zero;
  final isSingleLine = editable.maxLines == 1;
  if (isSingleLine) {
    return editable.textDirection == TextDirection.rtl ? Offset(pixels, 0) : Offset(-pixels, 0);
  }
  return Offset(0, -pixels);
}

Rect _normalizeEditableRect(Rect rect, RenderEditable editable) {
  final minHeight = editable.preferredLineHeight;
  const double leftPadding = 2.0; // cover leading-side clipping (e.g., descenders at start)
  return Rect.fromLTRB(
    rect.left - leftPadding,
    rect.top,
    rect.right,
    rect.top + minHeight,
  );
}

/// Canvas wrapper that collects paragraph word bounds while forwarding all
/// drawing to the underlying canvas.
class SpoilerCanvas implements Canvas {
  SpoilerCanvas(this.parent, this.context);

  final Canvas parent;
  final SpoilerPaintingContext context;

  @override
  void drawParagraph(ui.Paragraph paragraph, ui.Offset offset) {
    if (context.calculateRects) {
      var currentOffset = 0;
      while (true) {
        final range = paragraph.getWordBoundary(ui.TextPosition(offset: currentOffset));
        if (range.start == range.end) break;

        final fullText = context.currentText ?? '';

        if (fullText.length >= range.end) {
          final wordText = fullText.substring(range.start, range.end);
          final trimmed = wordText.trim();

          if (trimmed.isNotEmpty) {
            final trimStart = wordText.indexOf(trimmed);
            final start = range.start + trimStart;
            final end = start + trimmed.length;

            final boxes = paragraph.getBoxesForRange(start, end);
            for (final box in boxes) {
              final rect = box.toRect().shift(offset);
              context.spoilerRects.add(rect);
            }
          }
        }

        if (range.end <= currentOffset) break;
        currentOffset = range.end;
      }
    }

    parent.drawParagraph(paragraph, offset);
  }

  @override
  void save() => parent.save();
  @override
  void saveLayer(Rect? bounds, Paint paint) => parent.saveLayer(bounds, paint);
  @override
  void restore() => parent.restore();
  @override
  void restoreToCount(int count) => parent.restoreToCount(count);
  @override
  int getSaveCount() => parent.getSaveCount();
  @override
  void translate(double dx, double dy) => parent.translate(dx, dy);
  @override
  void scale(double sx, [double? sy]) => parent.scale(sx, sy);
  @override
  void rotate(double radians) => parent.rotate(radians);
  @override
  void skew(double sx, double sy) => parent.skew(sx, sy);
  @override
  void transform(Float64List matrix4) => parent.transform(matrix4);
  @override
  Float64List getTransform() => parent.getTransform();
  @override
  void clipRect(Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) =>
      parent.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) => parent.clipRRect(rrect, doAntiAlias: doAntiAlias);
  @override
  void clipPath(Path path, {bool doAntiAlias = true}) => parent.clipPath(path, doAntiAlias: doAntiAlias);
  @override
  Rect getLocalClipBounds() => parent.getLocalClipBounds();
  @override
  Rect getDestinationClipBounds() => parent.getDestinationClipBounds();
  @override
  void drawColor(Color color, BlendMode blendMode) => parent.drawColor(color, blendMode);
  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => parent.drawLine(p1, p2, paint);
  @override
  void drawPaint(Paint paint) => parent.drawPaint(paint);
  @override
  void drawRect(Rect rect, Paint paint) => parent.drawRect(rect, paint);
  @override
  void drawRRect(RRect rrect, Paint paint) => parent.drawRRect(rrect, paint);
  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) => parent.drawDRRect(outer, inner, paint);
  @override
  void drawOval(Rect rect, Paint paint) => parent.drawOval(rect, paint);
  @override
  void drawCircle(Offset c, double radius, Paint paint) => parent.drawCircle(c, radius, paint);
  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint) =>
      parent.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  @override
  void drawPath(Path path, Paint paint) => parent.drawPath(path, paint);
  @override
  void drawImage(ui.Image image, Offset p, Paint paint) => parent.drawImage(image, p, paint);
  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) => parent.drawImageRect(image, src, dst, paint);
  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) =>
      parent.drawImageNine(image, center, dst, paint);
  @override
  void drawPicture(ui.Picture picture) => parent.drawPicture(picture);
  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) =>
      parent.drawPoints(pointMode, points, paint);
  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) =>
      parent.drawVertices(vertices, blendMode, paint);
  @override
  void drawAtlas(ui.Image atlas, List<RSTransform> transforms, List<Rect> rects, List<Color>? colors,
          BlendMode? blendMode, Rect? cullRect, Paint paint) =>
      parent.drawAtlas(atlas, transforms, rects, colors, blendMode, cullRect, paint);
  @override
  void drawRawAtlas(ui.Image atlas, Float32List rstTransforms, Float32List rects, Int32List? colors,
          BlendMode? blendMode, Rect? cullRect, Paint paint) =>
      parent.drawRawAtlas(atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
  @override
  void drawShadow(Path path, Color color, double elevation, bool transparentOccluder) =>
      parent.drawShadow(path, color, elevation, transparentOccluder);
  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) =>
      parent.drawRawPoints(pointMode, points, paint);

  @override
  void clipRSuperellipse(dynamic rsuperellipse, {bool doAntiAlias = true}) {
    // ignore: avoid_dynamic_calls
    (parent as dynamic).clipRSuperellipse(rsuperellipse, doAntiAlias: doAntiAlias);
  }

  @override
  void drawRSuperellipse(dynamic rsuperellipse, ui.Paint paint) {
    // ignore: avoid_dynamic_calls
    (parent as dynamic).drawRSuperellipse(rsuperellipse, paint);
  }
}
