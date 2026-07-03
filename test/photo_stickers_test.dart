import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/photo_stickers.dart';

void main() {
  group('decodePhotoStickers', () {
    test('null/blank decodes to empty', () {
      expect(decodePhotoStickers(null), isEmpty);
      expect(decodePhotoStickers('  '), isEmpty);
    });

    test('parses a JSON array of nullable strings', () {
      expect(decodePhotoStickers('["😊",null,"🌸"]'), ['😊', null, '🌸']);
    });

    test('malformed JSON decodes to empty (never throws)', () {
      expect(decodePhotoStickers('not json'), isEmpty);
    });

    test('non-list JSON decodes to empty', () {
      expect(decodePhotoStickers('{"a":1}'), isEmpty);
    });

    test('non-string elements become null', () {
      expect(decodePhotoStickers('[1,"😊",true]'), [null, '😊', null]);
    });
  });

  group('encodePhotoStickers', () {
    test('all-null list encodes to null (byte-identical old records)', () {
      expect(encodePhotoStickers([null, null]), isNull);
      expect(encodePhotoStickers(const []), isNull);
    });

    test('trims trailing nulls before encoding', () {
      expect(encodePhotoStickers(['😊', null, null]), '["😊"]');
    });

    test('keeps interior nulls (index alignment matters)', () {
      expect(encodePhotoStickers(['😊', null, '🌸']), '["😊",null,"🌸"]');
    });
  });

  group('stickerAt', () {
    test('returns the value at index', () {
      expect(stickerAt(['😊', '🌸'], 1), '🌸');
    });

    test('out-of-range index is null', () {
      expect(stickerAt(['😊'], 5), isNull);
      expect(stickerAt(const [], 0), isNull);
    });
  });

  group('withStickerAt', () {
    test('sets an existing index without mutating the input', () {
      final input = ['😊', '🌸'];
      final next = withStickerAt(input, 0, '🥰');
      expect(next, ['🥰', '🌸']);
      expect(input, ['😊', '🌸']); // unchanged
    });

    test('pads with nulls when setting past the current length', () {
      expect(withStickerAt(['😊'], 2, '🥰'), ['😊', null, '🥰']);
    });

    test('clearing sets that index back to null', () {
      expect(withStickerAt(['😊', '🌸'], 1, null), ['😊', null]);
    });
  });
}
