import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/entry_detail/reading_time.dart';

void main() {
  group('readingCharCount', () {
    test('trims and counts graphemes (한글·이모지 = 1)', () {
      expect(readingCharCount('  안녕 😀  '), 4); // 안 녕 space 😀
      expect(readingCharCount(''), 0);
      expect(readingCharCount('   '), 0);
    });
  });

  group('readingMinutes', () {
    test('short entries return 0 (no estimate)', () {
      expect(readingMinutes(0), 0);
      expect(readingMinutes(279), 0);
    });

    test('rounds up at the 400 chars/min pace', () {
      expect(readingMinutes(280), 1);
      expect(readingMinutes(400), 1);
      expect(readingMinutes(401), 2);
      expect(readingMinutes(800), 2);
    });
  });

  group('readingMetaLabel', () {
    test('empty text yields empty label', () {
      expect(readingMetaLabel('   '), '');
    });

    test('short text shows only the char count', () {
      expect(readingMetaLabel('짧은 기록'), '5자');
    });

    test('long text appends the reading-time estimate', () {
      final long = '가' * 640;
      expect(readingMetaLabel(long), '640자 · 약 2분 읽기');
    });
  });
}
