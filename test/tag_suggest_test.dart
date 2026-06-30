import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/tags/tag_suggest.dart';

void main() {
  group('suggestTags', () {
    final all = ['여행', '가족', '일상', '육아', '제주도'];

    test('empty query returns all (minus excluded), order preserved', () {
      expect(suggestTags(all, '', const ['가족']),
          ['여행', '일상', '육아', '제주도']);
    });

    test('filters by case-insensitive substring', () {
      expect(suggestTags(['Travel', 'travelogue', '여행'], 'travel', const []),
          ['Travel', 'travelogue']);
    });

    test('excludes already-added tags', () {
      expect(suggestTags(all, '', const ['여행', '제주도']),
          ['가족', '일상', '육아']);
    });

    test('respects the limit', () {
      final many = List.generate(20, (i) => 't$i');
      expect(suggestTags(many, '', const [], limit: 5).length, 5);
    });

    test('no match yields empty', () {
      expect(suggestTags(all, 'zzz', const []), isEmpty);
    });
  });

  group('normalizeTag', () {
    test('trims surrounding whitespace', () {
      expect(normalizeTag('  여행  '), '여행');
    });

    test('strips leading hash marks', () {
      expect(normalizeTag('#여행'), '여행');
      expect(normalizeTag('## 가족'), '가족');
    });

    test('collapses internal whitespace to single spaces', () {
      expect(normalizeTag('제주  여행'), '제주 여행');
      expect(normalizeTag('a\t\tb'), 'a b');
    });

    test('null for empty, blank, or hash-only input', () {
      expect(normalizeTag(''), isNull);
      expect(normalizeTag('   '), isNull);
      expect(normalizeTag('##'), isNull);
    });
  });

  group('withTagAdded', () {
    test('appends a new tag', () {
      expect(withTagAdded(const ['여행'], '가족'), ['여행', '가족']);
    });

    test('skips a case-insensitive duplicate', () {
      expect(withTagAdded(const ['travel'], 'Travel'), ['travel']);
      expect(withTagAdded(const ['여행'], '여행'), ['여행']);
    });

    test('does not mutate the input list', () {
      final original = ['여행'];
      withTagAdded(original, '가족');
      expect(original, ['여행']);
    });

    test('adds to an empty list', () {
      expect(withTagAdded(const [], '여행'), ['여행']);
    });
  });

  group('splitTagInput', () {
    test('splits on commas', () {
      expect(splitTagInput('여행, 가족'), ['여행', '가족']);
    });

    test('splits on newlines and fullwidth/japanese commas', () {
      expect(splitTagInput('여행，가족、일상\n추억'),
          ['여행', '가족', '일상', '추억']);
    });

    test('keeps spaces inside a tag (only commas split)', () {
      expect(splitTagInput('제주 여행, 가족'), ['제주 여행', '가족']);
    });

    test('normalizes each piece and drops blanks/hash-only', () {
      expect(splitTagInput(' #여행 ,  , ##'), ['여행']);
    });

    test('single tag returns a one-element list', () {
      expect(splitTagInput('여행'), ['여행']);
    });
  });

  group('withTagsAdded', () {
    test('adds several tags from one input', () {
      expect(withTagsAdded(const ['일상'], '여행, 가족'),
          ['일상', '여행', '가족']);
    });

    test('skips duplicates against existing and within the input', () {
      expect(withTagsAdded(const ['travel'], 'Travel, family, FAMILY'),
          ['travel', 'family']);
    });

    test('does not mutate the input list', () {
      final original = ['여행'];
      withTagsAdded(original, '가족, 일상');
      expect(original, ['여행']);
    });

    test('blank input leaves the list unchanged', () {
      expect(withTagsAdded(const ['여행'], '  ,  '), ['여행']);
    });
  });

  group('longTagHint', () {
    test('null when every tag fits', () {
      expect(longTagHint(const ['여행', '가족', '제주도여행이야기']), isNull);
      expect(longTagHint(const []), isNull);
    });

    test('hint when any tag is too long', () {
      expect(longTagHint(const ['여행', '열다섯글자를훌쩍넘기는아주긴태그입니다']), isNotNull);
      expect(longTagHint(const ['열다섯글자를훌쩍넘기는아주긴태그입니다']), contains('길'));
    });

    test('counts graphemes, not code units', () {
      // 16 single-grapheme chars > default max 15
      expect(longTagHint(['a' * 16]), isNotNull);
      expect(longTagHint(['a' * 15]), isNull);
    });

    test('respects a custom max', () {
      expect(longTagHint(const ['네글자임'], max: 3), isNotNull);
      expect(longTagHint(const ['네글자임'], max: 5), isNull);
    });
  });

  group('tagCountHint', () {
    test('null at or below the default threshold', () {
      expect(tagCountHint(0), isNull);
      expect(tagCountHint(6), isNull);
    });

    test('returns a hint past the threshold', () {
      expect(tagCountHint(7), isNotNull);
      expect(tagCountHint(20), contains('많'));
    });

    test('respects a custom max', () {
      expect(tagCountHint(3, max: 3), isNull);
      expect(tagCountHint(4, max: 3), isNotNull);
    });
  });
}
