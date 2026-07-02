import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/write/emoji_picker.dart';

void main() {
  group('insertIntoText', () {
    test('inserts at a collapsed cursor mid-text', () {
      final (text, offset) =
          insertIntoText('ab', const TextSelection.collapsed(offset: 1), '😊');
      expect(text, 'a😊b');
      expect(offset, 3); // 1 + '😊'.length(2) — UTF-16 기준
    });

    test('replaces the selected range', () {
      final (text, offset) = insertIntoText(
          'hello', const TextSelection(baseOffset: 1, extentOffset: 4), 'X');
      expect(text, 'hXo');
      expect(offset, 2);
    });

    test('appends to the end when the cursor sits there', () {
      final (text, offset) =
          insertIntoText('hi', const TextSelection.collapsed(offset: 2), '😊');
      expect(text, 'hi😊');
      expect(offset, 4);
    });

    test('inserts into empty text', () {
      final (text, offset) =
          insertIntoText('', const TextSelection.collapsed(offset: 0), '😊');
      expect(text, '😊');
      expect(offset, 2);
    });

    test('appends when there is no valid cursor (-1)', () {
      final (text, offset) =
          insertIntoText('hi', const TextSelection.collapsed(offset: -1), '!');
      expect(text, 'hi!');
      expect(offset, 3);
    });

    test('appends when the offset is past the end', () {
      final (text, offset) =
          insertIntoText('hi', const TextSelection.collapsed(offset: 99), '!');
      expect(text, 'hi!');
      expect(offset, 3);
    });

    test('catalog is non-empty and has no duplicates', () {
      expect(kDiaryEmojis, isNotEmpty);
      expect(kDiaryEmojis.toSet().length, kDiaryEmojis.length);
    });
  });
}
