import 'package:flutter/painting.dart' show Alignment;
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/photo_crops.dart';

void main() {
  group('photoCropAlignmentForChoice', () {
    test('null/blank/center/unknown → null (중앙, keep the centre)', () {
      expect(photoCropAlignmentForChoice(null), isNull);
      expect(photoCropAlignmentForChoice('  '), isNull);
      expect(photoCropAlignmentForChoice('center'), isNull);
      expect(photoCropAlignmentForChoice('nope'), isNull);
    });

    test('known ids map to the matching Alignment', () {
      expect(photoCropAlignmentForChoice('top'), Alignment.topCenter);
      expect(photoCropAlignmentForChoice('bottom'), Alignment.bottomCenter);
      expect(photoCropAlignmentForChoice('left'), Alignment.centerLeft);
      expect(photoCropAlignmentForChoice('right'), Alignment.centerRight);
    });
  });

  group('decodePhotoCrops', () {
    test('null/blank decodes to empty', () {
      expect(decodePhotoCrops(null), isEmpty);
      expect(decodePhotoCrops('   '), isEmpty);
    });

    test('parses a JSON array, keeping known ids and nulling the rest', () {
      expect(decodePhotoCrops('["top",null,"bottom"]'),
          ['top', null, 'bottom']);
      expect(decodePhotoCrops('["left","bogus","right"]'),
          ['left', null, 'right']);
    });

    test('malformed / non-list JSON decodes to empty (never throws)', () {
      expect(decodePhotoCrops('not json'), isEmpty);
      expect(decodePhotoCrops('{"a":1}'), isEmpty);
    });
  });

  group('encodePhotoCrops', () {
    test('all null/unknown → null (byte-identical to legacy rows)', () {
      expect(encodePhotoCrops(const []), isNull);
      expect(encodePhotoCrops(const [null, null]), isNull);
      expect(encodePhotoCrops(const [null, 'bogus']), isNull);
    });

    test('trims trailing null/unknown entries', () {
      expect(encodePhotoCrops(const ['top', null, null]), '["top"]');
      expect(encodePhotoCrops(const [null, 'bottom', null]), '[null,"bottom"]');
    });

    test('normalises unknown ids to null in kept range', () {
      expect(encodePhotoCrops(const ['bogus', 'right']), '[null,"right"]');
    });
  });

  group('cropAt', () {
    test('reads in-range, null out of range', () {
      const list = ['top', null, 'bottom'];
      expect(cropAt(list, 0), 'top');
      expect(cropAt(list, 1), isNull);
      expect(cropAt(list, 2), 'bottom');
      expect(cropAt(list, 3), isNull);
      expect(cropAt(list, -1), isNull);
    });
  });

  group('withCropAt', () {
    test('sets a choice, padding with null as needed', () {
      expect(withCropAt(const [], 2, 'top'), [null, null, 'top']);
      expect(withCropAt(const ['bottom'], 0, 'left'), ['left']);
    });

    test('unknown/blank id clears to null', () {
      expect(withCropAt(const ['top'], 0, 'bogus'), [null]);
      expect(withCropAt(const ['top'], 0, null), [null]);
    });
  });
}
