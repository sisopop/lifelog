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

  group('readingMinutes', () {
    test('returns null below the 200-char threshold', () {
      expect(readingMinutes(0), isNull);
      expect(readingMinutes(199), isNull);
    });

    test('rounds up to whole minutes at ~500 chars/min', () {
      expect(readingMinutes(200), 1);
      expect(readingMinutes(500), 1);
      expect(readingMinutes(501), 2);
      expect(readingMinutes(1000), 2);
      expect(readingMinutes(1200), 3);
    });
  });

  group('suggestTitleFromContent', () {
    test('uses the first non-empty trimmed line', () {
      expect(suggestTitleFromContent('  제주 여행  \n둘째 날'), '제주 여행');
      expect(suggestTitleFromContent('\n\n첫 줄은 비었다 아래가 첫 줄'),
          '첫 줄은 비었다 아래가 첫 줄');
    });

    test('null when the body is empty or whitespace-only', () {
      expect(suggestTitleFromContent(''), isNull);
      expect(suggestTitleFromContent('   \n\t\n  '), isNull);
    });

    test('null when the first line is too long to be a title (> 50)', () {
      expect(suggestTitleFromContent('가' * 51), isNull);
      expect(suggestTitleFromContent('가' * 50), '가' * 50);
    });
  });

  group('extractHashtagSuggestions', () {
    test('extracts #tokens in first-seen order, stripping the #', () {
      expect(
        extractHashtagSuggestions('오늘 #여행 #가족 좋았다', const []),
        ['여행', '가족'],
      );
    });

    test('excludes tags already added (case-insensitive)', () {
      expect(
        extractHashtagSuggestions('#Jeju #Seoul', const ['jeju']),
        ['Seoul'],
      );
    });

    test('de-duplicates repeats case-insensitively', () {
      expect(
        extractHashtagSuggestions('#cafe #Cafe #park', const []),
        ['cafe', 'park'],
      );
    });

    test('ignores a lone # with no following word', () {
      expect(extractHashtagSuggestions('# ## end #', const []), isEmpty);
    });

    test('empty when there are no hashtags', () {
      expect(extractHashtagSuggestions('평범한 하루였다', const []), isEmpty);
    });

    test('caps the number of suggestions at max', () {
      expect(
        extractHashtagSuggestions('#a #b #c #d', const [], max: 2),
        ['a', 'b'],
      );
    });
  });
}
