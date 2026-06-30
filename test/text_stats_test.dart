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
      expect(writingMilestone(49), isNull);
    });

    test('returns the highest milestone reached', () {
      expect(writingMilestone(50), '🌱 좋은 시작이에요');
      expect(writingMilestone(99), '🌱 좋은 시작이에요');
      expect(writingMilestone(100), '✍️ 벌써 100자를 넘겼어요');
      expect(writingMilestone(299), '✍️ 벌써 100자를 넘겼어요');
      expect(writingMilestone(300), '✨ 300자, 술술 써지네요');
      expect(writingMilestone(499), '✨ 300자, 술술 써지네요');
      expect(writingMilestone(500), '🔥 500자를 넘겼어요!');
      expect(writingMilestone(999), '🔥 500자를 넘겼어요!');
      expect(writingMilestone(1000), '🏆 1000자 돌파, 대단해요!');
      expect(writingMilestone(1999), '🏆 1000자 돌파, 대단해요!');
      expect(writingMilestone(2000), '📚 2000자, 한 편의 글이 됐어요');
      expect(writingMilestone(5000), '📚 2000자, 한 편의 글이 됐어요');
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

    test('falls back to the first sentence when the line is too long', () {
      expect(
        suggestTitleFromContent('짧은 제목. ${'가' * 60}'),
        '짧은 제목',
      );
    });

    test('null when even the first sentence is too long', () {
      expect(suggestTitleFromContent('${'가' * 60}. 나머지'), isNull);
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

    test('strips trailing sentence punctuation from a tag', () {
      expect(
        extractHashtagSuggestions('오늘 #가족, #여행. 좋았다', const []),
        ['가족', '여행'],
      );
    });

    test('de-dupes tags that differ only by trailing punctuation', () {
      expect(
        extractHashtagSuggestions('#cafe #cafe!', const []),
        ['cafe'],
      );
    });

    test('ignores a token that is only punctuation', () {
      expect(extractHashtagSuggestions('#... #!? end', const []), isEmpty);
    });
  });

  group('frequentTagSuggestions', () {
    test('keeps ranked order and drops tags already on the entry', () {
      expect(
        frequentTagSuggestions(['가족', '여행', '카페'], ['여행']),
        ['가족', '카페'],
      );
    });

    test('caps at max', () {
      expect(
        frequentTagSuggestions(['a', 'b', 'c'], const [], max: 2),
        ['a', 'b'],
      );
    });

    test('empty when every available tag is already added', () {
      expect(frequentTagSuggestions(['a', 'b'], ['a', 'b']), isEmpty);
    });

    test('empty when there are no tags yet', () {
      expect(frequentTagSuggestions(const [], const []), isEmpty);
    });
  });

  group('countSentences', () {
    test('counts segments split by sentence-ending punctuation', () {
      expect(countSentences('밥을 먹었다. 산책도 했다! 좋은 날이었나?'), 3);
    });

    test('text with no terminator is a single sentence', () {
      expect(countSentences('그냥 평범한 하루'), 1);
    });

    test('line breaks separate sentences', () {
      expect(countSentences('첫 줄\n\n둘째 줄'), 2);
    });

    test('repeated terminators do not inflate the count', () {
      expect(countSentences('대박!! 진짜??'), 2);
    });

    test('empty / punctuation-or-whitespace only is zero', () {
      expect(countSentences(''), 0);
      expect(countSentences('   \n  '), 0);
      expect(countSentences('...!?'), 0);
    });
  });

  group('countParagraphs', () {
    test('blocks separated by a blank line count separately', () {
      expect(countParagraphs('첫 문단\n\n둘째 문단'), 2);
    });

    test('a single line break does not split a paragraph', () {
      expect(countParagraphs('한 문단\n같은 문단'), 1);
    });

    test('text with no blank line is a single paragraph', () {
      expect(countParagraphs('그냥 평범한 하루'), 1);
    });

    test('whitespace-only blank line still separates', () {
      expect(countParagraphs('위\n   \n아래'), 2);
    });

    test('extra blank lines do not inflate the count', () {
      expect(countParagraphs('하나\n\n\n\n둘'), 2);
    });

    test('empty / whitespace only is zero', () {
      expect(countParagraphs(''), 0);
      expect(countParagraphs('   \n  \n '), 0);
    });
  });

  group('countQuestions', () {
    test('counts question sentences', () {
      expect(countQuestions('왜 그럴까? 그냥 그렇다. 어떻게 하지?'), 2);
    });

    test('repeated question marks count once', () {
      expect(countQuestions('진짜?? 정말?'), 2);
    });

    test('handles the fullwidth question mark', () {
      expect(countQuestions('정말？ 그래'), 1);
    });

    test('zero when there are no questions', () {
      expect(countQuestions('그냥 평범한 하루였다.'), 0);
      expect(countQuestions(''), 0);
    });
  });

  group('averageSentenceLength', () {
    test('null below 2 sentences', () {
      expect(averageSentenceLength(''), isNull);
      expect(averageSentenceLength('한 문장뿐'), isNull);
    });

    test('rounds chars / sentence count', () {
      // "가나다. 라마." → 8 graphemes (incl. space), 2 sentences → 4
      expect(averageSentenceLength('가나다. 라마.'), 4);
    });

    test('rounds to nearest whole number', () {
      // "a. b. c." → 8 graphemes (incl. spaces), 3 sentences → 2.67 → 3
      expect(averageSentenceLength('a. b. c.'), 3);
    });
  });
}
