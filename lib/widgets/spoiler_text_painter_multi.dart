import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:spoiler_widget/widgets/canvas_callback_painter.dart';

/// Collects all visible text paragraphs inside [child], reports their
/// bounding regions, and repaints them on top of the original subtree.
///
/// Usage:
///   - Wrap any subtree with [SpoilerTextPainterMulti].
///   - Provide [onInit] to get a list of text regions (for masks/particles).
///   - Provide [onPaint] to draw custom effects (e.g. particles, clipPath).
///   - Text itself is repainted using [TextPainter] based on collected
///     [RenderParagraph]s.
@immutable
class SpoilerTextPainterMulti extends StatefulWidget {
  const SpoilerTextPainterMulti({
    super.key,
    required this.child,
    required this.onInit,
    required this.onPaint,
    this.repaint,
  });

  /// Subtree that contains text widgets (Text, RichText, etc.).
  final Widget child;

  /// Called whenever visible text regions are recomputed.
  final ValueChanged<List<Rect>> onInit;

  /// Custom paint callback executed *before* text is repainted.
  ///
  /// Typical usage:
  ///  - draw particles
  ///  - apply clipPath for spoiler mask
  final PaintCallback onPaint;

  /// Optional external repaint notifier (e.g. animation controller).
  final Listenable? repaint;

  @override
  State<SpoilerTextPainterMulti> createState() => _SpoilerTextPainterMultiState();
}

class _SpoilerTextPainterMultiState extends State<SpoilerTextPainterMulti> {
  final List<_ParagraphEntry> _entries = <_ParagraphEntry>[];
  List<Rect> _regions = const [];

  /// Incremented whenever paragraph data changes.
  int _rev = 0;

  /// Ensures we only schedule one recompute per frame.
  bool _recomputeScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleRecompute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleRecompute();
  }

  @override
  void didUpdateWidget(covariant SpoilerTextPainterMulti oldWidget) {
    super.didUpdateWidget(oldWidget);

    final childChanged = oldWidget.child != widget.child;

    if (childChanged) {
      _scheduleRecompute();
    }
  }

  /// Schedule recomputation of paragraphs and regions on the next frame.
  void _scheduleRecompute() {
    if (_recomputeScheduled) return;
    _recomputeScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recomputeScheduled = false;
      _recompute();
    });
  }

  /// Walks the render tree under this widget, collects all RenderParagraphs,
  /// builds TextPainters for them, and computes regions
  void _recompute() {
    if (!mounted) return;

    final root = context.findRenderObject();
    if (root is! RenderBox) return;

    final textScaler = MediaQuery.maybeOf(context)?.textScaler ?? TextScaler.noScaling;

    final collector = _TextRegionCollector(
      root: root,
      textScaler: textScaler,
    );

    collector.collect();

    _entries
      ..clear()
      ..addAll(collector.entries);

    _regions = List<Rect>.unmodifiable(collector.regions);
    _rev++;

    widget.onInit(_regions);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        // When layout changes (size of subtree), recompute paragraph info.
        _scheduleRecompute();
        return false;
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          SizeChangedLayoutNotifier(
            child: widget.child,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CanvasCallbackMulti(
                  entries: _entries,
                  onPaint: widget.onPaint,
                  token: _rev,
                  repaint: widget.repaint,
                ),
                isComplex: true,
                willChange: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encapsulates logic of walking the render tree, collecting text paragraphs
/// and their corresponding regions (word-wise or selection-wise).
class _TextRegionCollector {
  _TextRegionCollector({
    required this.root,
    required this.textScaler,
  });

  final RenderBox root;
  final TextScaler textScaler;

  final List<_ParagraphEntry> entries = <_ParagraphEntry>[];
  final List<Rect> regions = <Rect>[];

  /// Entry point for collecting paragraphs and regions.
  void collect() {
    final stack = <RenderObject>[root];

    // DFS over visible render subtree to find all RenderParagraphs.
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      node.visitChildren(stack.add);

      if (node is! RenderParagraph) continue;

      _processParagraph(node);
    }
  }

  void _processParagraph(RenderParagraph rp) {
    final span = rp.text;

    final tp = TextPainter(
      text: span,
      textDirection: rp.textDirection,
      textAlign: rp.textAlign,
      maxLines: rp.maxLines,
      ellipsis: rp.overflow == TextOverflow.ellipsis ? '…' : null,
      locale: rp.locale,
      textScaler: textScaler,
    );

    tp.layout(maxWidth: rp.size.width);

    final toWrapper = rp.getTransformTo(root);
    entries.add(_ParagraphEntry(tp: tp, toWrapper: toWrapper));

    _collectWordRegions(tp, toWrapper);
  }

  /// Collect regions for each non-empty word using TextPainter word boundaries.
  void _collectWordRegions(TextPainter tp, Matrix4 toWrapper) {
    final plain = tp.text?.toPlainText() ?? '';
    if (plain.isEmpty) return;

    int offset = 0;
    final length = plain.length;

    while (offset < length) {
      final wordRange = tp.getWordBoundary(TextPosition(offset: offset));
      if (wordRange.isCollapsed) {
        offset++;
        continue;
      }

      final sub = plain.substring(wordRange.start, wordRange.end);
      if (sub.trim().isEmpty) {
        offset = wordRange.end;
        continue;
      }

      final boxes = tp.getBoxesForSelection(
        TextSelection(
          baseOffset: wordRange.start,
          extentOffset: wordRange.end,
        ),
      );

      if (boxes.isNotEmpty) {
        final rect = MatrixUtils.transformRect(toWrapper, boxes.first.toRect());
        if (_isNonEmpty(rect)) {
          regions.add(rect);
        }
      }

      offset = wordRange.end;
    }
  }

  bool _isNonEmpty(Rect rect) => rect.width > 0.0 && rect.height > 0.0;
}

/// Internal holder for a paragraph and its transform from local to wrapper space.
class _ParagraphEntry {
  _ParagraphEntry({
    required this.tp,
    required this.toWrapper,
  });

  final TextPainter tp;
  final Matrix4 toWrapper;
}

/// Custom painter that:
///   1) runs [onPaint] (to set up effects like clipPath/particles),
///   2) repaints all text paragraphs on top of the original subtree.
class _CanvasCallbackMulti extends CustomPainter {
  _CanvasCallbackMulti({
    required this.entries,
    required this.onPaint,
    required this.token,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final List<_ParagraphEntry> entries;
  final PaintCallback onPaint;
  final int token;

  @override
  void paint(Canvas canvas, Size size) {
    onPaint(canvas, size);

    for (final entry in entries) {
      canvas.save();
      canvas.transform(entry.toWrapper.storage);
      entry.tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasCallbackMulti oldDelegate) {
    if (oldDelegate.token != token) return true;
    if (oldDelegate.entries.length != entries.length) return true;

    for (var i = 0; i < entries.length; i++) {
      if (!identical(oldDelegate.entries[i].tp, entries[i].tp) ||
          !identical(oldDelegate.entries[i].toWrapper, entries[i].toWrapper)) {
        return true;
      }
    }

    return true;
  }
}
