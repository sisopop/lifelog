import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/photo_frames.dart';

void main() {
  group('decodePhotoFrames', () {
    test('null/blank decodes to empty', () {
      expect(decodePhotoFrames(null), isEmpty);
      expect(decodePhotoFrames('  '), isEmpty);
    });

    test('parses a JSON array of nullable strings', () {
      expect(decodePhotoFrames('["white",null,"black"]'),
          ['white', null, 'black']);
    });

    test('malformed JSON decodes to empty (never throws)', () {
      expect(decodePhotoFrames('not json'), isEmpty);
    });

    test('non-list JSON decodes to empty', () {
      expect(decodePhotoFrames('{"a":1}'), isEmpty);
    });

    test('non-string elements become null', () {
      expect(decodePhotoFrames('[1,"white",true]'), [null, 'white', null]);
    });
  });

  group('encodePhotoFrames', () {
    test('all-null list encodes to null (byte-identical old records)', () {
      expect(encodePhotoFrames([null, null]), isNull);
      expect(encodePhotoFrames(const []), isNull);
    });

    test('trims trailing nulls before encoding', () {
      expect(encodePhotoFrames(['white', null, null]), '["white"]');
    });

    test('keeps interior nulls (index alignment matters)', () {
      expect(encodePhotoFrames(['white', null, 'black']),
          '["white",null,"black"]');
    });
  });

  group('frameAt', () {
    test('returns the value at index', () {
      expect(frameAt(['white', 'black'], 1), 'black');
    });

    test('out-of-range index is null', () {
      expect(frameAt(['white'], 5), isNull);
      expect(frameAt(const [], 0), isNull);
    });
  });

  group('withFrameAt', () {
    test('sets an existing index without mutating the input', () {
      final input = ['white', 'black'];
      final next = withFrameAt(input, 0, 'gold');
      expect(next, ['gold', 'black']);
      expect(input, ['white', 'black']); // unchanged
    });

    test('pads with nulls when setting past the current length', () {
      expect(withFrameAt(['white'], 2, 'gold'), ['white', null, 'gold']);
    });

    test('clearing sets that index back to null', () {
      expect(withFrameAt(['white', 'black'], 1, null), ['white', null]);
    });
  });
}
