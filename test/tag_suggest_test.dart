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
}
