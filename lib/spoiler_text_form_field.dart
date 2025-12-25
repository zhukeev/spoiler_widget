import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';

import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/widgets/spoiler_render_object.dart';

class SpoilerTextFieldWrapper extends StatefulWidget {
  const SpoilerTextFieldWrapper({
    super.key,
    required this.builder,
    required this.config,
    this.spoilerLabelBuilder,
    this.onSelectionChanged,
  });

  final SpoilerConfig config;
  final String Function()? spoilerLabelBuilder;
  final Widget Function(
    BuildContext context,
    EditableTextContextMenuBuilder? contextMenuBuilder,
  ) builder;
  final ValueChanged<TextSelection?>? onSelectionChanged;

  @override
  State<SpoilerTextFieldWrapper> createState() =>
      _SpoilerTextFieldWrapperState();
}

class _SpoilerTextFieldWrapperState extends State<SpoilerTextFieldWrapper>
    with TickerProviderStateMixin {
  late final SpoilerController _spoilerController =
      SpoilerController(vsync: this);

  TextSelection _spoilerSelection = const TextSelection.collapsed(offset: 0);

  @override
  void didUpdateWidget(covariant SpoilerTextFieldWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    final configChanged = oldWidget.config != widget.config;
    final childChanged = oldWidget.builder != widget.builder;

    if (configChanged || childChanged) {
      _spoilerController.updateConfiguration(widget.config);
    }
  }

  EditableTextContextMenuBuilder _buildContextMenu() {
    return (context, editableTextState) {
      final selection = editableTextState.textEditingValue.selection;

      final items = editableTextState.contextMenuButtonItems.toList();

      if (selection.isValid && !selection.isCollapsed) {
        items.add(
          ContextMenuButtonItem(
            label: widget.spoilerLabelBuilder?.call() ?? 'Spoiler',
            onPressed: () {
              final value = editableTextState.textEditingValue;

              editableTextState.hideToolbar();

              editableTextState.userUpdateTextEditingValue(
                value.copyWith(
                  selection: TextSelection.collapsed(
                    offset: value.selection.extentOffset,
                  ),
                ),
                SelectionChangedCause.toolbar,
              );

              _spoilerSelection = value.selection;
              widget.onSelectionChanged?.call(_spoilerSelection);
              _spoilerController.enable();
            },
          ),
        );
      }

      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: editableTextState.contextMenuAnchors,
        buttonItems: items,
      );
    };
  }

  @override
  void dispose() {
    _spoilerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, _buildContextMenu());
    return ListenableBuilder(
      listenable: _spoilerController,
      child: child,
      builder: (context, _) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          if (widget.config.enableGestureReveal) {
            _spoilerController.toggle(details.localPosition);
          }
        },
        child: SpoilerRenderObjectWidget(
          onPaint: (canvas, size) {
            if (_spoilerController.isEnabled) {
              _spoilerController.drawParticles(canvas);
            }
          },
          textSelection: _spoilerSelection,
          onClipPath: (size) =>
              _spoilerController.createSplashPathMaskClipper(size),
          onInit: (rects) {
            final path = Path();
            for (final rect in rects) {
              path.addRect(rect);
            }
            _spoilerController.initializeParticles(
              path,
              widget.config,
              rects: rects,
            );
          },
          child: child,
        ),
      ),
    );
  }
}
