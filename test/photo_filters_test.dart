import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/photo_filters.dart';

void main() {
  group('colorMatrixForChoice', () {
    test('null/blank/unknown → null (원본, natural colours)', () {
      expect(colorMatrixForChoice(null), isNull);
      expect(colorMatrixForChoice('  '), isNull);
      expect(colorMatrixForChoice('original'), isNull);
      expect(colorMatrixForChoice('nope'), isNull);
    });

    test('known ids map to a 20-element (5×4) colour matrix', () {
      for (final id in ['mono', 'sepia', 'warm', 'cool']) {
        final m = colorMatrixForChoice(id);
        expect(m, isNotNull, reason: id);
        expect(m!.length, 20, reason: id);
      }
    });
  });

  group('decodePhotoFilters', () {
    test('null/blank decodes to empty', () {
      expect(decodePhotoFilters(null), isEmpty);
      expect(decodePhotoFilters('   '), isEmpty);
    });

    test('parses a JSON array, keeping known ids and nulling the rest', () {
      expect(decodePhotoFilters('["mono",null,"sepia"]'),
          ['mono', null, 'sepia']);
      expect(decodePhotoFilters('["mono","bogus","cool"]'),
          ['mono', null, 'cool']);
    });

    test('malformed / non-list JSON decodes to empty (never throws)', () {
      expect(decodePhotoFilters('not json'), isEmpty);
      expect(decodePhotoFilters('{"a":1}'), isEmpty);
    });
  });

  group('encodePhotoFilters', () {
    test('all null/unknown → null (byte-identical to legacy rows)', () {
      expect(encodePhotoFilters(const []), isNull);
      expect(encodePhotoFilters(const [null, null]), isNull);
      expect(encodePhotoFilters(const [null, 'bogus']), isNull);
    });

    test('trims trailing null/unknown entries', () {
      expect(encodePhotoFilters(const ['mono', null, null]), '["mono"]');
      expect(encodePhotoFilters(const [null, 'sepia', null]), '[null,"sepia"]');
    });

    test('normalises unknown ids to null in kept range', () {
      expect(encodePhotoFilters(const ['bogus', 'cool']), '[null,"cool"]');
    });
  });

  group('filterAt', () {
    test('reads in-range, null out of range', () {
      const list = ['mono', null, 'sepia'];
      expect(filterAt(list, 0), 'mono');
      expect(filterAt(list, 1), isNull);
      expect(filterAt(list, 2), 'sepia');
      expect(filterAt(list, 3), isNull);
      expect(filterAt(list, -1), isNull);
    });
  });

  group('withFilterAt', () {
    test('sets a choice, padding with null as needed', () {
      expect(withFilterAt(const [], 2, 'mono'), [null, null, 'mono']);
      expect(withFilterAt(const ['sepia'], 0, 'cool'), ['cool']);
    });

    test('unknown/blank id clears to null', () {
      expect(withFilterAt(const ['mono'], 0, 'bogus'), [null]);
      expect(withFilterAt(const ['mono'], 0, null), [null]);
    });
  });
}
