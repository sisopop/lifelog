import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';
import 'package:lifelog/features/decorate/text_layer_rich.dart';
import 'package:lifelog/features/decorate/textbox_rich.dart';

// "글자 넣기" 레이어 리치텍스트(부분 서식) — 순수 로직·캔버스 연산·읽기 렌더 테스트.
void main() {
  group('seedTextLayerRich', () {
    test('plain layer (no flags) seeds nothing', () {
      expect(seedTextLayerRich(text: 'hi'), isNull);
    });

    test('empty text seeds nothing even with flags', () {
      expect(seedTextLayerRich(text: '', bold: true), isNull);
    });

    test('legacy whole-layer flags become whole-text attributes', () {
      final json = seedTextLayerRich(
        text: 'hi',
        bold: true,
        italic: true,
        underline: true,
        strike: true,
        bgColorValue: 0xFFFFF1A8,
      )!;
      final ops = jsonDecode(json) as List;
      expect(ops.first['insert'], 'hi');
      expect(ops.first['attributes'], {
        'bold': true,
        'italic': true,
        'underline': true,
        'strike': true,
        'background': '#fff1a8',
      });
      expect(ops.last['insert'], '\n'); // Quill 문서는 개행으로 끝난다
    });
  });

  group('richHasFormatting', () {
    test('null / broken JSON / plain delta → false', () {
      expect(richHasFormatting(null), isFalse);
      expect(richHasFormatting('not json'), isFalse);
      expect(richHasFormatting('[{"insert":"hi\\n"}]'), isFalse);
      expect(richHasFormatting('[{"insert":"hi","attributes":{}},{"insert":"\\n"}]'),
          isFalse);
    });

    test('any attribute → true', () {
      expect(
          richHasFormatting(
              '[{"insert":"a"},{"insert":"b","attributes":{"bold":true}},{"insert":"\\n"}]'),
          isTrue);
    });
  });

  group('richTextSpan for text layers', () {
    const rich =
        '[{"insert":"ab"},{"insert":"CD","attributes":{"bold":true}},{"insert":"\\n"}]';

    String flatten(InlineSpan s) => s.toPlainText();

    test('trimTrailingNewline drops the Quill end-of-document newline', () {
      final span = richTextSpan(
        richValue: rich,
        plainFallback: 'abCD',
        baseFontSize: 20,
        fontId: 'pretendard',
        baseColor: Colors.black,
        trimTrailingNewline: true,
      );
      expect(flatten(span), 'abCD');
    });

    test('default keeps the newline (textbox behaviour unchanged)', () {
      final span = richTextSpan(
        richValue: rich,
        plainFallback: 'abCD',
        baseFontSize: 20,
        fontId: 'pretendard',
        baseColor: Colors.black,
      );
      expect(flatten(span), 'abCD\n');
    });

    test('lineHeight null leaves the font default line height', () {
      final span = richTextSpan(
        richValue: rich,
        plainFallback: 'abCD',
        baseFontSize: 20,
        fontId: 'pretendard',
        baseColor: Colors.black,
        lineHeight: null,
      ) as TextSpan;
      expect(span.style!.height, isNull);
    });
  });

  group('text layer ops with richValue', () {
    const rich = '[{"insert":"hi","attributes":{"bold":true}},{"insert":"\\n"}]';

    test('addTextLayer stores richValue; default null', () {
      expect(
          addTextLayer(const PageCanvas(), 'a', 'hi', richValue: rich)
              .layers
              .single
              .richValue,
          rich);
      expect(addTextLayer(const PageCanvas(), 'a', 'hi').layers.single.richValue,
          isNull);
    });

    test('updateTextLayer sets and clears richValue', () {
      final c = addTextLayer(const PageCanvas(), 'a', 'hi');
      final withRich = updateTextLayer(c, 'a', 'hi', richValue: rich);
      expect(withRich.layers.single.richValue, rich);
      final cleared = updateTextLayer(withRich, 'a', 'hi');
      expect(cleared.layers.single.richValue, isNull);
    });

    test('updateTextLayer keeps flip and opacity (no longer reset)', () {
      final c = addTextLayer(const PageCanvas(), 'a', 'hi');
      final tweaked = PageCanvas(layers: [
        c.layers.single.copyWith(flipX: true, flipY: true, opacity: 0.5),
      ]);
      final l = updateTextLayer(tweaked, 'a', 'hello').layers.single;
      expect(l.value, 'hello');
      expect(l.flipX, isTrue);
      expect(l.flipY, isTrue);
      expect(l.opacity, 0.5);
    });

    test('text layer richValue survives toJson → fromJson', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi', richValue: rich)
          .layers
          .single;
      final back = DecoLayer.fromJson(l.toJson());
      expect(back.kind, DecoKind.text);
      expect(back.richValue, rich);
    });
  });
}
