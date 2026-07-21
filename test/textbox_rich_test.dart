import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/textbox_rich.dart';

// 텍스트박스 리치텍스트 공용 순수 로직(textbox_rich.dart)의 단위 테스트.
// 색 변환, 상대 크기 배율, Delta JSON → 읽기용 TextSpan 변환을 검증한다.
void main() {
  group('richColorHex / richParseColor', () {
    test('round-trips an opaque color as #RRGGBB', () {
      const c = Color(0xFF2F6FEB);
      expect(richColorHex(c), '#2f6feb');
      expect(richParseColor('#2f6feb'), const Color(0xFF2F6FEB));
    });

    test('parses #AARRGGBB and rejects non-hex', () {
      expect(richParseColor('#802f6feb'), const Color(0x802F6FEB));
      expect(richParseColor('blue'), isNull);
      expect(richParseColor(null), isNull);
      expect(richParseColor(42), isNull);
    });
  });

  group('richSizeMultiplier', () {
    test('maps size tokens, defaults to 1.0', () {
      expect(richSizeMultiplier(null), 1.0);
      expect(richSizeMultiplier('small'), 0.75);
      expect(richSizeMultiplier('large'), 1.4);
      expect(richSizeMultiplier('huge'), 1.8);
      expect(richSizeMultiplier('bogus'), 1.0);
    });
  });

  group('richTextSpan', () {
    test('falls back to plain text when richValue is null/blank/broken', () {
      for (final rv in [null, '', '   ', 'not json', '{"a":1}']) {
        final span = richTextSpan(
          richValue: rv,
          plainFallback: '평문',
          baseFontSize: 20,
          fontId: 'pretendard',
          baseColor: const Color(0xFF3A3A3A),
        ) as TextSpan;
        expect(span.text, '평문', reason: 'rv=$rv');
        expect(span.style!.fontSize, 20);
      }
    });

    test('applies per-run attributes from a Delta', () {
      const rich =
          '[{"insert":"보통 "},{"insert":"굵게","attributes":{"bold":true,"color":"#e5484d","size":"large"}},{"insert":"\\n"}]';
      final span = richTextSpan(
        richValue: rich,
        plainFallback: '보통 굵게',
        baseFontSize: 20,
        fontId: 'pretendard',
        baseColor: const Color(0xFF3A3A3A),
      ) as TextSpan;
      final runs = span.children!.cast<TextSpan>();
      expect(runs[0].text, '보통 ');
      expect(runs[0].style!.fontWeight, isNot(FontWeight.w700));
      expect(runs[1].text, '굵게');
      expect(runs[1].style!.fontWeight, FontWeight.w700);
      expect(runs[1].style!.color, const Color(0xFFE5484D));
      expect(runs[1].style!.fontSize, closeTo(20 * 1.4, 1e-9));
    });

    test('maps underline+strike+highlight+font', () {
      const rich =
          '[{"insert":"x","attributes":{"underline":true,"strike":true,"background":"#fff1a8","font":"Jua"}}]';
      final span = richTextSpan(
        richValue: rich,
        plainFallback: 'x',
        baseFontSize: 16,
        fontId: 'pretendard',
        baseColor: const Color(0xFF3A3A3A),
      ) as TextSpan;
      final run = span.children!.cast<TextSpan>().first;
      expect(run.style!.decoration,
          TextDecoration.combine([TextDecoration.underline, TextDecoration.lineThrough]));
      expect(run.style!.backgroundColor, const Color(0xFFFFF1A8));
      expect(run.style!.fontFamily, 'Jua');
    });
  });
}
