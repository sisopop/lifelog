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
