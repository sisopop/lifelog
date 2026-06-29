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

  group('writingMilestone', () {
    test('returns null below the first threshold', () {
      expect(writingMilestone(0), isNull);
      expect(writingMilestone(99), isNull);
    });

    test('returns the highest milestone reached', () {
      expect(writingMilestone(100), '✍️ 벌써 100자를 넘겼어요');
      expect(writingMilestone(299), '✍️ 벌써 100자를 넘겼어요');
      expect(writingMilestone(300), '✨ 300자, 술술 써지네요');
      expect(writingMilestone(499), '✨ 300자, 술술 써지네요');
      expect(writingMilestone(500), '🔥 500자를 넘겼어요!');
      expect(writingMilestone(999), '🔥 500자를 넘겼어요!');
      expect(writingMilestone(1000), '🏆 1000자 돌파, 대단해요!');
      expect(writingMilestone(5000), '🏆 1000자 돌파, 대단해요!');
    });
  });
}
