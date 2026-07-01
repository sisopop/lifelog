import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/text_highlight_catalog.dart';

void main() {
  group('kTextHighlightColors', () {
    test('is non-empty', () {
      expect(kTextHighlightColors, isNotEmpty);
    });

    test('colors are fully opaque (solid highlight block)', () {
      for (final c in kTextHighlightColors) {
        expect(c.a, 1.0, reason: '$c is translucent');
      }
    });

    test('no duplicate colors', () {
      final ints = kTextHighlightColors.map((c) => c.toARGB32()).toList();
      expect(ints.toSet().length, ints.length);
    });
  });
}
