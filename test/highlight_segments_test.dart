import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/shared/widgets/highlighted_text.dart';

void main() {
  group('highlightSegments', () {
    test('empty query returns the whole text as one non-match segment', () {
      expect(highlightSegments('제주도에서의 하루', ''),
          [const HighlightSegment('제주도에서의 하루', false)]);
      expect(highlightSegments('hello', '   '),
          [const HighlightSegment('hello', false)]);
    });

    test('empty text returns a single empty non-match segment', () {
      expect(highlightSegments('', 'x'),
          [const HighlightSegment('', false)]);
    });

    test('splits around a single match', () {
      expect(highlightSegments('제주도 여행', '여행'), [
        const HighlightSegment('제주도 ', false),
        const HighlightSegment('여행', true),
      ]);
    });

    test('match at the start has no leading segment', () {
      expect(highlightSegments('여행 일기', '여행'), [
        const HighlightSegment('여행', true),
        const HighlightSegment(' 일기', false),
      ]);
    });

    test('is case-insensitive but preserves original casing', () {
      expect(highlightSegments('Travel log', 'travel'), [
        const HighlightSegment('Travel', true),
        const HighlightSegment(' log', false),
      ]);
    });

    test('highlights every occurrence', () {
      expect(highlightSegments('가가가', '가'), [
        const HighlightSegment('가', true),
        const HighlightSegment('가', true),
        const HighlightSegment('가', true),
      ]);
    });

    test('no match returns the whole text as non-match', () {
      expect(highlightSegments('hello', 'zzz'),
          [const HighlightSegment('hello', false)]);
    });

    test('joining segment texts reproduces the original', () {
      const text = 'aXbXcX';
      final joined =
          highlightSegments(text, 'x').map((s) => s.text).join();
      expect(joined, text);
    });
  });
}
