import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/photo_tapes.dart';

void main() {
  group('decodePhotoTapes', () {
    test('null/blank decodes to empty', () {
      expect(decodePhotoTapes(null), isEmpty);
      expect(decodePhotoTapes('  '), isEmpty);
    });

    test('parses a JSON array of nullable strings', () {
      expect(decodePhotoTapes('["pink",null,"mint"]'), ['pink', null, 'mint']);
    });

    test('malformed JSON decodes to empty (never throws)', () {
      expect(decodePhotoTapes('not json'), isEmpty);
    });

    test('non-list JSON decodes to empty', () {
      expect(decodePhotoTapes('{"a":1}'), isEmpty);
    });

    test('non-string elements become null', () {
      expect(decodePhotoTapes('[1,"pink",true]'), [null, 'pink', null]);
    });
  });

  group('encodePhotoTapes', () {
    test('all-null list encodes to null (byte-identical old records)', () {
      expect(encodePhotoTapes([null, null]), isNull);
      expect(encodePhotoTapes(const []), isNull);
    });

    test('trims trailing nulls before encoding', () {
      expect(encodePhotoTapes(['pink', null, null]), '["pink"]');
    });

    test('keeps interior nulls (index alignment matters)', () {
      expect(encodePhotoTapes(['pink', null, 'mint']), '["pink",null,"mint"]');
    });
  });

  group('tapeAt', () {
    test('returns the value at index', () {
      expect(tapeAt(['pink', 'mint'], 1), 'mint');
    });

    test('out-of-range index is null', () {
      expect(tapeAt(['pink'], 5), isNull);
      expect(tapeAt(const [], 0), isNull);
    });
  });

  group('withTapeAt', () {
    test('sets an existing index without mutating the input', () {
      final input = ['pink', 'mint'];
      final next = withTapeAt(input, 0, 'blue');
      expect(next, ['blue', 'mint']);
      expect(input, ['pink', 'mint']); // unchanged
    });

    test('pads with nulls when setting past the current length', () {
      expect(withTapeAt(['pink'], 2, 'blue'), ['pink', null, 'blue']);
    });

    test('clearing sets that index back to null', () {
      expect(withTapeAt(['pink', 'mint'], 1, null), ['pink', null]);
    });
  });
}
