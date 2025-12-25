// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/models/spoiler_configs.dart';
import 'package:spoiler_widget/spoiler_text_form_field.dart';

void main() {
  testWidgets('SpoilerTextFieldWrapper adds menu item and reports selection',
      (tester) async {
    final controller = TextEditingController(text: 'Secret text');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    TextSelection? receivedSelection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpoilerTextFieldWrapper(
            config: SpoilerConfig(
              isEnabled: true,
              enableGestureReveal: true,
              enableFadeAnimation: false,
              particleConfig: const ParticleConfig(
                density: 0.0,
                speed: 0.0,
                color: Colors.white,
                maxParticleSize: 1.0,
              ),
            ),
            onSelectionChanged: (selection) => receivedSelection = selection,
            builder: (context, contextMenuBuilder) => TextField(
              controller: controller,
              focusNode: focusNode,
              contextMenuBuilder: contextMenuBuilder,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    focusNode.requestFocus();
    await tester.pump();

    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    const selection = TextSelection(baseOffset: 0, extentOffset: 6);

    editable.userUpdateTextEditingValue(
      editable.textEditingValue.copyWith(selection: selection),
      SelectionChangedCause.tap,
    );
    await tester.pump();

    editable.showToolbar();
    await tester.pump();

    expect(find.text('Spoiler'), findsOneWidget);

    await tester.tap(find.text('Spoiler'));
    await tester.pump();

    expect(receivedSelection, selection);
  });
}
