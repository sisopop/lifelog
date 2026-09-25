import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';
import 'package:lifelog/features/decorate/page_canvas_view.dart';
import 'package:lifelog/features/decorate/text_layer_dialog.dart';

// "글자 넣기" 다이얼로그를 실제로 띄워 입력 → 서식 툴바 → 추가까지 조작하는 E2E
// 위젯 테스트(기기 없이 다이얼로그·툴바·저장값을 검증).
Widget _host(void Function(TextLayerInput?) onResult, {TextLayerInput? initial}) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ko')],
    locale: const Locale('ko'),
    home: Builder(
      builder: (ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async =>
                onResult(await showTextLayerDialog(ctx, initial: initial)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

QuillController _quill(WidgetTester t) =>
    t.widget<QuillEditor>(find.byType(QuillEditor)).controller;

// 실제 자판 입력과 같은 경로(controller.replaceText → 리스너 알림)로 글을 넣는다.
void _type(QuillController q, String text) => q.replaceText(
    0, 0, text, TextSelection.collapsed(offset: text.length));

void main() {
  testWidgets('bold with no selection formats the whole text and is saved as rich',
      (tester) async {
    TextLayerInput? result;
    await tester.pumpWidget(_host((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final q = _quill(tester);
    _type(q, 'Hello');
    await tester.pump();

    await tester.tap(find.byTooltip('굵게'));
    await tester.pump();
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.text, 'Hello');
    expect(result!.bold, isFalse); // 레이어 플래그 대신 Delta가 서식을 담는다
    final ops = jsonDecode(result!.richValue!) as List;
    expect(ops.first['insert'], 'Hello');
    expect(ops.first['attributes'], {'bold': true});
  });

  testWidgets('bold on a selection formats only that part', (tester) async {
    TextLayerInput? result;
    await tester.pumpWidget(_host((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final q = _quill(tester);
    _type(q, 'abcdef');
    q.updateSelection(
        const TextSelection(baseOffset: 2, extentOffset: 4), ChangeSource.local);
    await tester.pump();
    await tester.tap(find.byTooltip('굵게'));
    await tester.pump();
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    final ops = (jsonDecode(result!.richValue!) as List).cast<Map>();
    final bolded = ops
        .where((o) => (o['attributes'] as Map?)?['bold'] == true)
        .map((o) => o['insert'])
        .join();
    expect(bolded, 'cd');
  });

  testWidgets('plain text with no formatting stores richValue null', (tester) async {
    TextLayerInput? result;
    await tester.pumpWidget(_host((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    _type(_quill(tester), 'plain');
    await tester.pump();
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    expect(result!.text, 'plain');
    expect(result!.richValue, isNull);
  });

  testWidgets('editing a legacy bold layer seeds bold over the whole text',
      (tester) async {
    TextLayerInput? result;
    await tester.pumpWidget(_host((r) => result = r,
        initial: const TextLayerInput('old', 0xFF3A3A3A, true, null)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('글자 편집'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final ops = jsonDecode(result!.richValue!) as List;
    expect(ops.first['insert'], 'old');
    expect(ops.first['attributes'], {'bold': true});
  });

  testWidgets('add button is disabled over the 40-char limit', (tester) async {
    await tester.pumpWidget(_host((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    _type(_quill(tester), 'x' * 41);
    await tester.pump();
    final btn = tester.widget<TextButton>(find.widgetWithText(TextButton, '추가'));
    expect(btn.onPressed, isNull);
    expect(find.text('41/40'), findsOneWidget);
  });

  testWidgets('canvas renders a rich text layer without the trailing newline',
      (tester) async {
    const rich =
        '[{"insert":"ab"},{"insert":"CD","attributes":{"bold":true}},{"insert":"\\n"}]';
    final layer = addTextLayer(const PageCanvas(), 'a', 'abCD', richValue: rich)
        .layers
        .single;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: decoLayerContent(layer, stickerSize: 20)),
    ));
    final rt = tester.widget<RichText>(find.byType(RichText).first);
    expect(rt.text.toPlainText(), 'abCD');
  });
}
