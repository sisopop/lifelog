import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/write/text_stats.dart';

void main() {
  group('textStats', () {
    test('empty / whitespace-only is zero', () {
      expect(textStats('').chars, 0);
      expect(textStats('').words, 0);
      expect(textStats('   \n\t ').chars, 0);
      expect(textStats('   \n\t ').words, 0);
    });

    test('counts ascii words and chars, trims edges', () {
      final s = textStats('  hello world  ');
      expect(s.chars, 11); // "hello world"
      expect(s.words, 2);
    });

    test('collapses multiple whitespace between words', () {
      final s = textStats('a   b\n\nc');
      expect(s.words, 3);
      expect(s.chars, 8); // "a   b\n\nc"
    });

    test('Korean syllables count as one grapheme each', () {
      final s = textStats('가족 여행');
      expect(s.chars, 5); // 가 족 (space) 여 행
      expect(s.words, 2);
    });

    test('emoji counts as a single character', () {
      final s = textStats('👨‍👩‍👧');
      expect(s.chars, 1);
      expect(s.words, 1);
    });
  });
}
