import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/photo_aspects.dart';

void main() {
  group('aspectRatioForChoice', () {
    test('null/blank/unknown → null (원본, natural ratio)', () {
      expect(aspectRatioForChoice(null), isNull);
      expect(aspectRatioForChoice('  '), isNull);
      expect(aspectRatioForChoice('original'), isNull);
      expect(aspectRatioForChoice('nope'), isNull);
    });

    test('known ids map to their box ratio', () {
      expect(aspectRatioForChoice('square'), 1.0);
      expect(aspectRatioForChoice('wide'), 4 / 3);
      expect(aspectRatioForChoice('tall'), 3 / 4);
    });
  });

  group('decodePhotoAspects', () {
    test('null/blank decodes to empty', () {
      expect(decodePhotoAspects(null), isEmpty);
      expect(decodePhotoAspects('   '), isEmpty);
    });

    test('parses a JSON array, keeping known ids and nulling the rest', () {
      expect(decodePhotoAspects('["square",null,"tall"]'),
          ['square', null, 'tall']);
      expect(decodePhotoAspects('["square","bogus","wide"]'),
          ['square', null, 'wide']);
    });

    test('malformed / non-list JSON decodes to empty (never throws)', () {
      expect(decodePhotoAspects('not json'), isEmpty);
      expect(decodePhotoAspects('{"a":1}'), isEmpty);
    });
  });

  group('encodePhotoAspects', () {
    test('all null/unknown → null (byte-identical to legacy rows)', () {
      expect(encodePhotoAspects(const []), isNull);
      expect(encodePhotoAspects(const [null, null]), isNull);
      expect(encodePhotoAspects(const [null, 'bogus']), isNull);
    });

    test('trims trailing null/unknown entries', () {
      expect(encodePhotoAspects(const ['square', null, null]), '["square"]');
      expect(encodePhotoAspects(const [null, 'wide', null]),
          '[null,"wide"]');
    });

    test('normalises unknown ids to null in kept range', () {
      expect(encodePhotoAspects(const ['bogus', 'tall']), '[null,"tall"]');
    });
  });

  group('aspectAt', () {
    test('reads in-range, null out of range', () {
      const list = ['square', null, 'wide'];
      expect(aspectAt(list, 0), 'square');
      expect(aspectAt(list, 1), isNull);
      expect(aspectAt(list, 2), 'wide');
      expect(aspectAt(list, 3), isNull);
      expect(aspectAt(list, -1), isNull);
    });
  });

  group('withAspectAt', () {
    test('sets a choice, padding with null as needed', () {
      expect(withAspectAt(const [], 2, 'square'), [null, null, 'square']);
      expect(withAspectAt(const ['wide'], 0, 'tall'), ['tall']);
    });

    test('unknown/blank id clears to null', () {
      expect(withAspectAt(const ['square'], 0, 'bogus'), [null]);
      expect(withAspectAt(const ['square'], 0, null), [null]);
    });
  });
}
