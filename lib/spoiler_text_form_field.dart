import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/utils/spoiler_text_layout.dart.dart';
import 'package:spoiler_widget/widgets/canvas_callback_painter.dart';

typedef ContextMenuLabelBuilder = String Function();

/// TextField-based spoiler input that keeps the native context menu.
class SpoilerTextFormField extends StatefulWidget {
  const SpoilerTextFormField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.config,
    required this.cursorColor,
    this.decoration = const InputDecoration(),
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.spoilerLabelBuilder,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final TextSpoilerConfig config;

  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final bool expands;

  final Color cursorColor;
  final InputDecoration decoration;
  final ContextMenuLabelBuilder? spoilerLabelBuilder;

  @override
  State<SpoilerTextFormField> createState() => _SpoilerTextFormFieldState();
}

class _SpoilerTextFormFieldState extends State<SpoilerTextFormField> with TickerProviderStateMixin {
  late final SpoilerController _spoilerController = SpoilerController(vsync: this);
  final GlobalKey<EditableTextState> _editableKey = GlobalKey<EditableTextState>();

  Path? _spoilerPath;
  TextSelection? _spoilerSelection;
  bool _forceEnabled = false;
  bool _pendingRenderSync = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _spoilerSelection = widget.config.textSelection;
    _forceEnabled = widget.config.isEnabled;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromRenderEditable());
  }

  @override
  void didUpdateWidget(covariant SpoilerTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }

    if (oldWidget.config != widget.config) {
      _spoilerSelection = widget.config.textSelection;
      _forceEnabled = widget.config.isEnabled;
      _scheduleRenderSync();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _spoilerController.dispose();
    super.dispose();
  }

  TextSelection? get _effectiveSelection => _spoilerSelection ?? widget.config.textSelection;

  TextSpoilerConfig get _effectiveConfig {
    final selection = _effectiveSelection;
    if (selection == null) return widget.config.copyWith(isEnabled: _forceEnabled || widget.config.isEnabled);
    return widget.config.copyWith(
      textSelection: selection,
      isEnabled: true,
    );
  }

  void _onControllerChanged() {
    setState(() {});
    _scheduleRenderSync();
  }

  void _scheduleRenderSync() {
    if (_pendingRenderSync) return;
    _pendingRenderSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingRenderSync = false;
      _syncFromRenderEditable();
    });
  }

  void _syncFromRenderEditable() {
    final selection = _effectiveSelection;
    final render = _editableKey.currentState?.renderEditable;
    if (selection == null || render == null || !selection.isValid || selection.isCollapsed) return;

    final boxes = render.getBoxesForSelection(selection);
    if (boxes.isEmpty) return;

    final path = Path();
    for (final box in boxes) {
      path.addRect(box.toRect());
    }

    setState(() {
      _spoilerPath = path;
    });

    _spoilerController.initializeParticles(path, _effectiveConfig);
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.config.textStyle ?? DefaultTextStyle.of(context).style;
    final direction = Directionality.of(context);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (details) {
        if (widget.config.enableGestureReveal) {
          _spoilerController.toggle(details.localPosition);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final selection = _effectiveSelection;
          final layout = computeSpoilerTextLayout(
            text: widget.controller.text,
            style: baseStyle,
            textAlign: widget.config.textAlign ?? TextAlign.start,
            textDirection: direction,
            maxLines: widget.expands ? null : widget.maxLines,
            isEllipsis: false,
            range: selection,
            maxWidth: constraints.maxWidth,
          );

          // Fallback path if renderEditable hasn't produced boxes yet.
          if (_spoilerPath == null && selection != null) {
            final path = Path()..addPath(layout.wordPath, Offset.zero);
            _spoilerPath = path;
            _spoilerController.initializeParticles(path, _effectiveConfig);
          }

          final decoration = widget.decoration.copyWith(
            border: widget.decoration.border ?? InputBorder.none,
            isCollapsed: widget.decoration.isCollapsed ?? true,
            contentPadding: widget.decoration.contentPadding ?? EdgeInsets.zero,
          );

          return CustomPaint(
            foregroundPainter: CustomPainterCanvasCallback(
              repaint: _spoilerController,
              onPaint: (canvas, size) {
                final textMask = _spoilerController.createSplashPathMaskClipper(size);
                final particleClip = _spoilerController.createClipPath(size);

                canvas.save();
                if (_spoilerController.isEnabled) {
                  // Hide text within the spoiler region using controller-provided clipper.
                  canvas.clipPath(textMask);
                }
                layout.painter.paint(canvas, Offset.zero);
                canvas.restore();

                if (_spoilerController.isEnabled) {
                  canvas.save();
                  canvas.clipPath(particleClip);
                  _spoilerController.drawParticles(canvas);
                  canvas.restore();
                }
              },
            ),
            child: TextFormField(
              key: _editableKey,
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: baseStyle.copyWith(color: Colors.transparent),
              cursorColor: widget.cursorColor,
              textAlign: widget.config.textAlign ?? TextAlign.start,
              textDirection: direction,
              maxLines: widget.expands ? null : widget.maxLines,
              minLines: widget.expands ? null : widget.minLines,
              expands: widget.expands,
              obscureText: widget.obscureText,
              decoration: decoration,
              contextMenuBuilder: (context, editableTextState) {
                final items = <ContextMenuButtonItem>[
                  ...editableTextState.contextMenuButtonItems,
                ];
                final sel = editableTextState.textEditingValue.selection;

                if (sel.isValid && !sel.isCollapsed) {
                  items.add(
                    ContextMenuButtonItem(
                      label: widget.spoilerLabelBuilder?.call() ?? 'Spoiler',
                      onPressed: () {
                        editableTextState.hideToolbar();

                        setState(() {
                          _spoilerSelection = sel;
                          _forceEnabled = true;
                          _spoilerPath = null; // recompute from render
                        });

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _spoilerController.updateConfiguration(_effectiveConfig);
                          _spoilerController.enable();
                          _syncFromRenderEditable();
                        });
                      },
                    ),
                  );
                }

                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: items,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
