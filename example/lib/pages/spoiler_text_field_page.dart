import 'package:flutter/material.dart';
import 'package:spoiler_widget/spoiler_widget.dart';

class SpoilerTextFieldPage extends StatefulWidget {
  const SpoilerTextFieldPage({super.key});

  @override
  State<SpoilerTextFieldPage> createState() => _SpoilerTextFieldPageState();
}

class _SpoilerTextFieldPageState extends State<SpoilerTextFieldPage> {
  final _controller = TextEditingController(text: 'This is a spoiler! Tap to reveal');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SpoilerTextField')),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SpoilerTextFieldWrapper(
            config:  SpoilerConfig(
              isEnabled: true,
              enableGestureReveal: true,
            ),
            builder: (context, contextMenuBuilder) => TextFormField(
              controller: _controller,
              focusNode: FocusNode(),
              contextMenuBuilder: contextMenuBuilder,
              cursorColor: Colors.deepPurple,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
