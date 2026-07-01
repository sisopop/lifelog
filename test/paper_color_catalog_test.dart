import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/paper_color_catalog.dart';

void main() {
  group('kPaperColors', () {
    test('is non-empty', () {
      expect(kPaperColors, isNotEmpty);
    });

    test('colors are fully opaque (solid paper tint)', () {
      for (final c in kPaperColors) {
        expect(c.a, 1.0, reason: '$c is translucent');
      }
    });

    test('no duplicate colors', () {
      final ints = kPaperColors.map((c) => c.toARGB32()).toList();
      expect(ints.toSet().length, ints.length);
    });

    test('default cream is not in the pickable list (it is the null value)',
        () {
      final ints = kPaperColors.map((c) => c.toARGB32()).toSet();
      expect(ints.contains(kPaperDefaultCream.toARGB32()), isFalse);
    });
  });
}
