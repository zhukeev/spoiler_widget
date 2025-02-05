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

  List<Rect> spoilerRects = [];

  void initializeOffsets(StringDetails details) {
    spoilerRects = details.words.map((e) => e.rect).toList();

    // _controller.initializeParticles(spoilerRects);
    _controller.initializeParticles([Offset.zero & const Size.square(100)]);
  }

  @override
  void initState() {
    _controller = SpoilerController(
      particleColor: widget.configuration.particleColor,
      maxParticleSize: widget.configuration.maxParticleSize,
      fadeRadiusDeflate: widget.configuration.fadeRadius,
      speedOfParticles: widget.configuration.speedOfParticles,
      particleDensity: widget.configuration.particleDensity,
      fadeAnimationEnabled: widget.configuration.fadeAnimation,
      enableGesture: widget.configuration.enableGesture,
      initiallyEnabled: widget.configuration.isEnabled,
      vsync: this,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(covariant SpoilerTextWidget oldWidget) {
    if (oldWidget.configuration.selection != widget.configuration.selection ||
        oldWidget.configuration.style != widget.configuration.style) {
      _controller.disable();
    }

    if (oldWidget.configuration.isEnabled != widget.configuration.isEnabled) {
      _controller.onEnabledChanged(widget.configuration.isEnabled);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    _onTapRecognizer.dispose();
    super.dispose();
  }

  late final TapGestureRecognizer _onTapRecognizer = TapGestureRecognizer()
    ..onTapDown = (details) {
      if (widget.configuration.enableGesture) {
        final hasSelection = widget.configuration.selection != null;
        if (!hasSelection) {
          setState(() {
            _controller.toggle(details.localPosition);
          });
        } else if (spoilerRects.any((rect) => rect.contains(details.localPosition))) {
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

              _controller.drawParticles(offset, context.canvas);

              if (_controller.isFading) {
                context.pushClipPath(true, offset, _controller.spoilerBounds, _controller.splashPath, superPaint);
              }
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
