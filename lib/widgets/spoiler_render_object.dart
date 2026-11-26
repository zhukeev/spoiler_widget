// ignore_for_file: override_on_non_overriding_member

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'canvas_callback_painter.dart';
import 'package:spoiler_widget/utils/spoiler_path_builder.dart';
import 'package:spoiler_widget/utils/text_layout_client.dart';
import 'spoiler_canvas.dart';

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
    this.repaintListenable,
    this.enableOverlay = false,
  });

  final PaintCallback? onPaint;
  final PaintCallback? onAfterPaint;
  final Path Function(Size size)? onClipPath;
  final ValueChanged<List<Rect>>? onInit;
  final ui.ImageFilter? imageFilter;
  final bool enableOverlay;
  final TextSelection? textSelection;

  /// Fires when the spoiler's visuals advance (e.g. a particle animation
  /// tick). Triggers [RenderSpoiler.markNeedsPaint] directly, keeping widget
  /// rebuilds reserved for structural changes.
  final Listenable? repaintListenable;

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
      repaintListenable: repaintListenable,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSpoiler renderObject,
  ) {
    renderObject
      ..onPaint = onPaint
      ..onAfterPaint = onAfterPaint
      ..onClipPath = onClipPath
      ..onInit = onInit
      ..imageFilter = imageFilter
      ..textSelection = textSelection
      ..repaintListenable = repaintListenable
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
    Listenable? repaintListenable,
    bool enableOverlay = false,
    RenderBox? child,
  }) : _onPaint = onPaint,
       _onAfterPaint = onAfterPaint,
       _onClipPath = onClipPath,
       _onInit = onInit,
       _imageFilter = imageFilter,
       _repaintListenable = repaintListenable,
       _enableOverlay = enableOverlay,
       super(child);

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestSelf(Offset position) => true;

  final Set<ViewportOffset> _listenedOffsets = <ViewportOffset>{};

  List<RenderEditable> _findRenderEditables(
    RenderObject root, {
    Set<ViewportOffset>? offsets,
  }) {
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

  List<RenderParagraph> _findRenderParagraphs(RenderObject root) {
    final out = <RenderParagraph>[];

    void visit(RenderObject node) {
      if (node is RenderParagraph) {
        out.add(node);
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

  Listenable? _repaintListenable;
  Listenable? _repaintListeningTo;
  set repaintListenable(Listenable? value) {
    if (identical(_repaintListenable, value)) return;
    _repaintListenable = value;
    _syncRepaintListener();
  }

  void _syncRepaintListener() {
    final target = attached ? _repaintListenable : null;
    if (identical(target, _repaintListeningTo)) return;
    _repaintListeningTo?.removeListener(markNeedsPaint);
    _repaintListeningTo = target;
    _repaintListeningTo?.addListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _syncRepaintListener();
  }

  @override
  void performLayout() {
    super.performLayout();
    _rectsDirty = true;
    _subtreeScanValid = false;
  }

  bool _rectsDirty = true;
  int _lastInitRectsHash = 0;
  TextSelection? _lastSelection;
  List<Rect> _cachedSelectionRects = const [];

  // Cached render-subtree scan. The child subtree is only re-walked after
  // layout invalidates it — previously every paint traversed it twice.
  List<RenderEditable> _cachedEditables = const [];
  List<RenderParagraph> _cachedParagraphs = const [];
  Set<ViewportOffset> _cachedVisitedOffsets = const {};
  bool _subtreeScanValid = false;

  void _ensureSubtreeScan() {
    if (_subtreeScanValid) return;
    final childRo = child;
    final visited = <ViewportOffset>{};
    _cachedEditables = childRo != null
        ? _findRenderEditables(childRo, offsets: visited)
        : const <RenderEditable>[];
    _cachedParagraphs = childRo != null
        ? _findRenderParagraphs(childRo)
        : const <RenderParagraph>[];
    _cachedVisitedOffsets = visited;
    _subtreeScanValid = true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _ensureSubtreeScan();
    final editables = _cachedEditables;
    final paragraphs = _cachedParagraphs;
    final visitedOffsets = _cachedVisitedOffsets;
    final selection = _textSelection;

    final shouldRecalculate =
        _rectsDirty ||
        _lastSelection != selection ||
        _cachedSelectionRects.isEmpty;
    if (shouldRecalculate) {
      final collected = _collectSpoilerRects(
        editables: editables,
        paragraphs: paragraphs,
        selection: selection,
      );
      _updateCachedRects(collected);
      _lastSelection = selection;
      _rectsDirty = false;
    }

    final clipPath = _normalizeClipPath(_onClipPath?.call(size));

    if (_enableOverlay) {
      super.paint(context, offset);

      if (clipPath == null &&
          _onPaint == null &&
          _onAfterPaint == null &&
          _imageFilter == null) {
        _syncEditableOffsets(visitedOffsets);
        return;
      }

      if (clipPath != null) {
        context.pushClipPath(
          needsCompositing,
          offset,
          paintBounds.shift(offset),
          clipPath,
          (c, o) {
            _paintOverlayContent(c, o);
          },
        );
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

      void paintParticlesIfAny(PaintCallback? callback) {
        if (callback == null) return;
        if (particleClipPath != null) {
          spoilerContext.pushClipPath(
            needsCompositing,
            layerOffset,
            paintBounds.shift(layerOffset),
            particleClipPath,
            (c, o) {
              _drawParticles(c, o, callback);
            },
          );
        } else {
          _drawParticles(spoilerContext, layerOffset, callback);
        }
      }

      paintParticlesIfAny(_onPaint);

      if (clipPath != null) {
        spoilerContext.pushClipPath(
          needsCompositing,
          layerOffset,
          paintBounds.shift(layerOffset),
          clipPath,
          (c, o) {
            _paintChildWithFilter(c, o);
          },
        );
      } else {
        _paintChildWithFilter(spoilerContext, layerOffset);
      }

      paintParticlesIfAny(_onAfterPaint);
    }

    final rootSpoilerContext = SpoilerPaintingContext(
      layer: layer!,
      estimatedBounds: paintBounds.shift(offset),
      calculateRects: _rectsDirty,
    );

    paintSpoilerLayer(rootSpoilerContext, offset);

    // ignore: invalid_use_of_protected_member
    rootSpoilerContext.stopRecordingIfNeeded();

    _syncEditableOffsets(visitedOffsets);
  }

  void _paintOverlayContent(PaintingContext context, Offset offset) {
    _drawParticles(context, offset, _onPaint);

    if (_imageFilter != null) {
      context.pushLayer(BackdropFilterLayer(filter: _imageFilter!), (
        childContext,
        childOffset,
      ) {
        _drawParticles(childContext, childOffset, _onAfterPaint);
      }, offset);
    } else {
      _drawParticles(context, offset, _onAfterPaint);
    }
  }

  void _drawParticles(
    PaintingContext currentContext,
    Offset currentOffset,
    PaintCallback? callback,
  ) {
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
    markNeedsPaint();
  }

  @override
  void detach() {
    _repaintListeningTo?.removeListener(markNeedsPaint);
    _repaintListeningTo = null;
    for (final offset in _listenedOffsets) {
      offset.removeListener(_onEditableOffsetChanged);
    }
    _listenedOffsets.clear();
    _subtreeScanValid = false;
    super.detach();
  }

  SpoilerGeometry? _buildEditableGeometry(
    RenderEditable editable,
    TextSelection selection,
  ) {
    final text = editable.plainText;
    if (text.isEmpty) return null;
    return buildSpoilerGeometry(
      layout: RenderEditableLayoutClient(editable),
      text: text,
      selection: selection,
      skipWhitespace: true,
    );
  }

  List<Rect> _buildParagraphSelectionRects(
    RenderParagraph paragraph,
    int start,
    int end,
  ) {
    final text = paragraph.text.toPlainText();
    if (text.isEmpty) return const [];

    final int clampedStart = start.clamp(0, text.length);
    final int clampedEnd = end.clamp(0, text.length);
    if (clampedStart >= clampedEnd) return const [];

    final geom = buildSpoilerGeometry(
      layout: RenderParagraphLayoutClient(paragraph),
      text: text,
      selection: TextSelection(
        baseOffset: clampedStart,
        extentOffset: clampedEnd,
      ),
      skipWhitespace: true,
    );
    return geom?.rects ?? const [];
  }

  List<Rect> _collectSpoilerRects({
    required List<RenderEditable> editables,
    required List<RenderParagraph> paragraphs,
    required TextSelection? selection,
  }) {
    final collected = <Rect>[];

    void appendEditable(RenderEditable editable, TextSelection selection) {
      final geom = _buildEditableGeometry(editable, selection);
      if (geom == null) return;

      final Matrix4 m = editable.getTransformTo(this);
      final Offset paintOffset = editablePaintOffset(editable);
      collected.addAll(
        geom.rects
            .map((r) => normalizeEditableRect(r.shift(paintOffset), editable))
            .map((r) => MatrixUtils.transformRect(m, r)),
      );
    }

    void appendParagraph(RenderParagraph paragraph, int start, int end) {
      final rects = _buildParagraphSelectionRects(paragraph, start, end);
      if (rects.isEmpty) return;

      final Matrix4 m = paragraph.getTransformTo(this);
      collected.addAll(rects.map((r) => MatrixUtils.transformRect(m, r)));
    }

    if (selection != null) {
      for (final editable in editables) {
        appendEditable(editable, selection);
      }

      // TextSelection.start/end are already ordered (start <= end).
      final rawStart = selection.start;
      final rawEnd = selection.end;
      int paragraphOffset = 0;

      for (final paragraph in paragraphs) {
        final text = paragraph.text.toPlainText();
        final length = text.length;
        if (length == 0) continue;

        final int localStart = (rawStart - paragraphOffset).clamp(0, length);
        final int localEnd = (rawEnd - paragraphOffset).clamp(0, length);
        if (localStart >= localEnd) {
          paragraphOffset += length;
          if (paragraphOffset >= rawEnd) break;
          continue;
        }

        appendParagraph(paragraph, localStart, localEnd);
        paragraphOffset += length;
        if (paragraphOffset >= rawEnd) break;
      }
    } else {
      for (final editable in editables) {
        final text = editable.plainText;
        if (text.isEmpty) continue;
        appendEditable(
          editable,
          TextSelection(baseOffset: 0, extentOffset: text.length),
        );
      }

      for (final paragraph in paragraphs) {
        final text = paragraph.text.toPlainText();
        if (text.isEmpty) continue;
        appendParagraph(paragraph, 0, text.length);
      }
    }

    return collected;
  }

  void _updateCachedRects(List<Rect> rects) {
    final previousRects = _cachedSelectionRects;
    final previousHash = _lastInitRectsHash;
    final nextHash = _hashRects(rects);

    _cachedSelectionRects = rects;

    if (nextHash != previousHash || previousRects.length != rects.length) {
      _lastInitRectsHash = nextHash;
      _onInit?.call(rects);
    }
  }
}
