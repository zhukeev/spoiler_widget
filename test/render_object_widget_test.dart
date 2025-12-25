import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoiler_widget/widgets/spoiler_render_object.dart';

void main() {
  testWidgets('SpoilerRenderObjectWidget reports text rects', (tester) async {
    List<Rect> rects = const [];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          child: SpoilerRenderObjectWidget(
            onInit: (value) => rects = value,
            child: const Text('Hello world'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(rects, isNotEmpty);
  });

  testWidgets('SpoilerRenderObjectWidget reports selection rects for TextField',
      (tester) async {
    final controller = TextEditingController(text: 'Hello world');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    List<Rect> rects = const [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpoilerRenderObjectWidget(
            textSelection: const TextSelection(baseOffset: 0, extentOffset: 5),
            onInit: (value) => rects = value,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(rects, isNotEmpty);
  });
}
