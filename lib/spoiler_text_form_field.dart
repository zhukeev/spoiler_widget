import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/widgets/canvas_callback_painter.dart';
import 'package:spoiler_widget/widgets/path_clipper.dart';
import 'package:spoiler_widget/utils/text_layout_client.dart';

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
  final GlobalKey _editableKey = GlobalKey();
  late final VoidCallback _controllerListener = () {
    _forceEnabled = _spoilerController.isEnabled;
    setState(() {}); 
  };

  ViewportOffset? _scrollOffset;
  String? _spoilerSignature;
  TextSelection? _spoilerSelection;
  bool _forceEnabled = false;
  bool _pendingRenderSync = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _spoilerController.addListener(_controllerListener);
    _spoilerSelection = widget.config.textSelection;
    _forceEnabled = widget.config.isEnabled;
    _scheduleRenderSync();
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
    _spoilerController.removeListener(_controllerListener);
    _scrollOffset?.removeListener(_scheduleRenderSync);
    _spoilerController.dispose();
    super.dispose();
  }

  TextSelection? get _effectiveSelection => _spoilerSelection ?? widget.config.textSelection;

  TextSpoilerConfig get _effectiveConfig {
    final selection = _effectiveSelection;
    if (selection == null) return widget.config.copyWith(isEnabled: _forceEnabled || widget.config.isEnabled);
    return widget.config.copyWith(
      textSelection: selection,
      isEnabled: _forceEnabled || _spoilerController.isEnabled,
    );
  }

  void _attachScrollOffset(RenderEditable? render) {
    final next = render?.offset;
    if (_scrollOffset == next) return;
    _scrollOffset?.removeListener(_scheduleRenderSync);
    _scrollOffset = next;
    _scrollOffset?.addListener(_scheduleRenderSync);
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
    final render = _findRenderEditable();
    final host = context.findRenderObject() as RenderBox?;

    if (selection == null || render == null || host == null || !selection.isValid || selection.isCollapsed) return;

    _attachScrollOffset(render);

    final _SpoilerGeometry? geom = _buildSpoilerPath(render, selection);
    if (geom == null) return;
    if (geom.signature == _spoilerSignature) return;

    final Matrix4 toHost = render.getTransformTo(host);
    final Path shiftedPath = Path()..addPath(geom.path, Offset.zero, matrix4: toHost.storage);

    setState(() {
      _spoilerSignature = geom.signature;
    });

    _spoilerController.initializeParticles(shiftedPath, _effectiveConfig);
    if (_effectiveConfig.isEnabled) {
      _spoilerController.enable();
    } else {
      _spoilerController.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.config.textStyle ?? DefaultTextStyle.of(context).style;
    final direction = Directionality.of(context);

    final decoration = widget.decoration.copyWith(
      border: widget.decoration.border ?? InputBorder.none,
      isCollapsed: widget.decoration.isCollapsed,
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (event) {
        if (!widget.config.enableGestureReveal) return;

        _spoilerController.toggle(event.localPosition);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _spoilerController,
            builder: (context, _) {
              return ClipPath(
                clipper: PathClipper(
                  builder: _spoilerController.createSplashPathMaskClipper,
                ),
                child: TextFormField(
                  key: _editableKey,
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  style: baseStyle,
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
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                foregroundPainter: CustomPainterCanvasCallback(
                  repaint: _spoilerController,
                  onPaint: (canvas, size) {
                    if (!_spoilerController.isEnabled) return;

                    canvas.clipRect(Offset.zero & size);
                    _spoilerController.drawParticles(canvas);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  RenderEditable? _findRenderEditable() {
    final RenderObject? root = _editableKey.currentContext?.findRenderObject();
    if (root == null) return null;
    if (root is RenderEditable) return root;

    RenderEditable? result;
    void visitor(RenderObject child) {
      if (child is RenderEditable) {
        result = child;
        return;
      }
      child.visitChildren(visitor);
    }

    root.visitChildren(visitor);
    return result;
  }

  _SpoilerGeometry? _buildSpoilerPath(RenderEditable render, TextSelection selection) {
    final text = widget.controller.text;
    if (text.isEmpty) return null;

    final layout = RenderEditableLayoutClient(render);
    final path = buildSelectionPath(
      layout: layout,
      text: text,
      selection: selection,
      skipWhitespace: true,
    );
    if (path == null) return null;

    final signature = StringBuffer();
    final bounds = path.getBounds();
    signature
      ..write(bounds.left)
      ..write(',')
      ..write(bounds.top)
      ..write(',')
      ..write(bounds.right)
      ..write(',')
      ..write(bounds.bottom);

    return _SpoilerGeometry(path: path, signature: signature.toString());
  }
}

class _SpoilerGeometry {
  _SpoilerGeometry({required this.path, required this.signature});
  final Path path;
  final String signature;
}
