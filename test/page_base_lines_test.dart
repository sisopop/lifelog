import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/paper_page.dart';

void main() {
  group('pageBaseLines', () {
    test('trims each line and drops blank lines', () {
      expect(
        pageBaseLines('  hello \n\n  world  \n   '),
        ['hello', 'world'],
      );
    });

    test('empty / whitespace-only body yields no lines', () {
      expect(pageBaseLines(''), isEmpty);
      expect(pageBaseLines('   \n\n  '), isEmpty);
    });

    test('keeps every line when within maxLines', () {
      expect(
        pageBaseLines('a\nb\nc', maxLines: 3),
        ['a', 'b', 'c'],
      );
    });

    test('clips to maxLines and marks the last shown line with an ellipsis', () {
      expect(
        pageBaseLines('a\nb\nc\nd', maxLines: 2),
        ['a', 'b…'],
      );
    });

    test('blank lines do not count toward maxLines', () {
      expect(
        pageBaseLines('a\n\n\nb\n\nc', maxLines: 3),
        ['a', 'b', 'c'],
      );
    });
  });
}
