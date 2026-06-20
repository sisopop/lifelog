import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/settings/reading_text_scale.dart';

void main() {
  group('readingScaleLabel', () {
    test('maps each supported scale to a label', () {
      expect(readingScaleLabel(0.9), '작게');
      expect(readingScaleLabel(1.0), '보통');
      expect(readingScaleLabel(1.15), '크게');
      expect(readingScaleLabel(1.3), '아주 크게');
    });
  });

  group('normalizeReadingScale', () {
    test('snaps to the nearest supported scale', () {
      expect(normalizeReadingScale(0.88), 0.9);
      expect(normalizeReadingScale(1.02), 1.0);
      expect(normalizeReadingScale(1.2), 1.15);
      expect(normalizeReadingScale(5.0), 1.3); // clamps to max
      expect(normalizeReadingScale(0.1), 0.9); // clamps to min
    });

    test('leaves an exact supported value unchanged', () {
      for (final s in readingTextScales) {
        expect(normalizeReadingScale(s), s);
      }
    });
  });
}
