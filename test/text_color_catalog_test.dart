import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/text_color_catalog.dart';

void main() {
  group('kTextInkColors', () {
    test('is non-empty', () {
      expect(kTextInkColors, isNotEmpty);
    });

    test('colors are fully opaque (readable ink)', () {
      for (final c in kTextInkColors) {
        expect(c.a, 1.0, reason: '$c is translucent');
      }
    });

    test('no duplicate colors', () {
      final ints = kTextInkColors.map((c) => c.toARGB32()).toList();
      expect(ints.toSet().length, ints.length);
    });
  });
}
