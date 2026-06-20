import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/search/recent_searches.dart';

void main() {
  group('addRecentSearch', () {
    test('pushes a new term to the front', () {
      expect(addRecentSearch(['a', 'b'], 'c'), ['c', 'a', 'b']);
    });

    test('ignores blank queries', () {
      expect(addRecentSearch(['a'], '   '), ['a']);
      expect(addRecentSearch(['a'], ''), ['a']);
    });

    test('trims the query before storing', () {
      expect(addRecentSearch([], '  hi  '), ['hi']);
    });

    test('moves an existing term to the front (case-insensitive)', () {
      expect(addRecentSearch(['old', 'Cat', 'x'], 'cat'), ['cat', 'old', 'x']);
    });

    test('keeps the freshly typed casing on re-search', () {
      expect(addRecentSearch(['cat'], 'CAT'), ['CAT']);
    });

    test('caps the list at max, dropping the oldest', () {
      final start = ['7', '6', '5', '4', '3', '2', '1', '0'];
      final result = addRecentSearch(start, '8');
      expect(result.length, recentSearchesMax);
      expect(result.first, '8');
      expect(result.contains('0'), isFalse);
    });
  });

  group('removeRecentSearch', () {
    test('removes a matching term (case-insensitive)', () {
      expect(removeRecentSearch(['Cat', 'dog'], 'cat'), ['dog']);
    });

    test('returns an equal list when nothing matches', () {
      expect(removeRecentSearch(['a', 'b'], 'z'), ['a', 'b']);
    });
  });
}
