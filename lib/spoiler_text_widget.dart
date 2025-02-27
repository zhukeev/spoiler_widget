import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:spoiler_widget/models/spoiler_controller.dart';
import 'package:spoiler_widget/models/string_details.dart';
import 'package:spoiler_widget/models/text_spoiler_configs.dart';
import 'package:spoiler_widget/widgets/spoiler_richtext.dart';

class SpoilerTextWidget extends StatefulWidget {
  const SpoilerTextWidget({
    super.key,
    required this.text,
    required this.configuration,
  });

  final TextSpoilerConfiguration configuration;
  final String text;

  @override
  State createState() => _SpoilerTextWidgetState();
}

class _SpoilerTextWidgetState extends State<SpoilerTextWidget> with TickerProviderStateMixin {
  late final SpoilerController _controller;
  final Path _spoilerPath = Path();

  void initializeOffsets(StringDetails details) {
    _spoilerPath.reset();

    for (final e in details.words) {
      _spoilerPath.addRect(e.rect);
    }
    _controller.initializeParticles(_spoilerPath, widget.configuration);
  }

  @override
  void initState() {
    _controller = SpoilerController(vsync: this);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SpoilerTextWidget oldWidget) {
    if (oldWidget.configuration != widget.configuration) {
      _controller.initializeParticles(_spoilerPath, widget.configuration);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
    _onTapRecognizer.dispose();
    _spoilerPath.reset();
  }

  late final TapGestureRecognizer _onTapRecognizer = TapGestureRecognizer()
    ..onTapDown = (details) {
      if (widget.configuration.enableGesture) {
        final hasSelection = widget.configuration.selection != null;
        if (!hasSelection) {
          setState(() {
            _controller.toggle(details.localPosition);
          });
        } else if (_spoilerPath.contains(details.localPosition)) {
          setState(() {
            _controller.toggle(details.localPosition);
          });
        }
      }
    };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: _controller,
        builder: (context, snapshot) {
          return SpoilerRichText(
            onBoundariesCalculated: initializeOffsets,
            key: UniqueKey(),
            selection: widget.configuration.selection,
            onPaint: (context, offset, superPaint) {
              if (!_controller.isEnabled) {
                superPaint(context, offset);
                return;
              }

              if (_controller.isFading) {
                context.pushClipPath(true, offset, _controller.spoilerBounds, _controller.splashPath, superPaint);
              }

              _controller.drawParticles(offset, context.canvas);

              // if we have a selection, draw the unselected path
              if (widget.configuration.selection != null) {
                context.pushClipPath(
                  true,
                  offset,
                  _controller.spoilerBounds,
                  _controller.excludeUnselectedPath,
                  superPaint,
                );
              }
            },
            initialized: _controller.isInitialized,
            text: TextSpan(
              text: widget.text,
              recognizer: widget.configuration.enableGesture ? _onTapRecognizer : null,
              style: widget.configuration.style,
            ),
          );
        });
  }
}
