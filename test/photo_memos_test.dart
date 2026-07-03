import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/photo_memos.dart';

void main() {
  group('decodePhotoMemos', () {
    test('null/blank decodes to empty', () {
      expect(decodePhotoMemos(null), isEmpty);
      expect(decodePhotoMemos('  '), isEmpty);
    });

    test('parses a JSON array of nullable strings', () {
      expect(decodePhotoMemos('["첫 사진",null,"바다"]'), ['첫 사진', null, '바다']);
    });

    test('malformed JSON decodes to empty (never throws)', () {
      expect(decodePhotoMemos('not json'), isEmpty);
    });

    test('non-list JSON decodes to empty', () {
      expect(decodePhotoMemos('{"a":1}'), isEmpty);
    });

    test('non-string or blank elements become null', () {
      expect(decodePhotoMemos('[1,"메모","  "]'), [null, '메모', null]);
    });
  });

  group('encodePhotoMemos', () {
    test('all-null/blank list encodes to null (byte-identical old records)', () {
      expect(encodePhotoMemos([null, null]), isNull);
      expect(encodePhotoMemos(const []), isNull);
      expect(encodePhotoMemos(['  ', null]), isNull);
    });

    test('trims trailing null/blank before encoding', () {
      expect(encodePhotoMemos(['메모', null, '  ']), '["메모"]');
    });

    test('keeps interior nulls (index alignment matters)', () {
      expect(encodePhotoMemos(['첫', null, '셋']), '["첫",null,"셋"]');
    });

    test('blank interior element normalises to null', () {
      expect(encodePhotoMemos(['첫', '   ', '셋']), '["첫",null,"셋"]');
    });
  });

  group('memoAt', () {
    test('returns the value at index', () {
      expect(memoAt(['첫', '둘'], 1), '둘');
    });

    test('out-of-range index is null', () {
      expect(memoAt(['첫'], 5), isNull);
      expect(memoAt(const [], 0), isNull);
    });
  });

  group('withMemoAt', () {
    test('sets (trimmed) an index without mutating the input', () {
      final input = ['첫', '둘'];
      final next = withMemoAt(input, 0, '  새 메모  ');
      expect(next, ['새 메모', '둘']);
      expect(input, ['첫', '둘']); // unchanged
    });

    test('pads with nulls when setting past the current length', () {
      expect(withMemoAt(['첫'], 2, '셋'), ['첫', null, '셋']);
    });

    test('clearing (null or blank) sets that index back to null', () {
      expect(withMemoAt(['첫', '둘'], 1, null), ['첫', null]);
      expect(withMemoAt(['첫', '둘'], 1, '   '), ['첫', null]);
    });
  });
}
