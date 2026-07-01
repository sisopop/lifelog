import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/washi_tape_catalog.dart';

void main() {
  group('kWashiTapes', () {
    test('is non-empty, each has a label and an id', () {
      expect(kWashiTapes, isNotEmpty);
      for (final t in kWashiTapes) {
        expect(t.id.trim(), isNotEmpty);
        expect(t.label.trim(), isNotEmpty);
      }
    });

    test('tape ids are unique', () {
      final ids = kWashiTapes.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('colors are translucent (so content shows through)', () {
      for (final t in kWashiTapes) {
        expect(t.color.a, lessThan(1.0), reason: '${t.id} is fully opaque');
      }
    });
  });

  group('washiTapeColor', () {
    test('returns the matching tape color', () {
      final first = kWashiTapes.first;
      expect(washiTapeColor(first.id), first.color);
    });

    test('unknown id falls back to the first tape (never throws)', () {
      expect(washiTapeColor('nope'), kWashiTapes.first.color);
      expect(washiTapeColor(''), kWashiTapes.first.color);
    });
  });
}
