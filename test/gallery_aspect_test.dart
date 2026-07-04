import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/entry_detail/gallery_aspect.dart';

void main() {
  group('galleryAspectRatio', () {
    test('null/zero/negative dimensions fall back to square (1.0)', () {
      expect(galleryAspectRatio(null, null), 1.0);
      expect(galleryAspectRatio(1000, null), 1.0);
      expect(galleryAspectRatio(null, 800), 1.0);
      expect(galleryAspectRatio(0, 800), 1.0);
      expect(galleryAspectRatio(1000, 0), 1.0);
      expect(galleryAspectRatio(-5, 800), 1.0);
    });

    test('a square photo stays 1.0', () {
      expect(galleryAspectRatio(1080, 1080), 1.0);
    });

    test('a moderate portrait keeps its natural ratio', () {
      // 3:4 portrait = 0.75, exactly the lower bound.
      expect(galleryAspectRatio(900, 1200), closeTo(0.75, 1e-9));
    });

    test('a moderate landscape keeps its natural ratio', () {
      // 4:3 landscape ≈ 1.333, exactly the upper bound.
      expect(galleryAspectRatio(1200, 900), closeTo(4 / 3, 1e-9));
    });

    test('an extreme tall photo is clamped to 3/4', () {
      // 9:16 portrait (0.5625) would be too tall — clamp up to 0.75.
      expect(galleryAspectRatio(1080, 1920), closeTo(0.75, 1e-9));
    });

    test('an extreme wide photo is clamped to 4/3', () {
      // 16:9 landscape (1.777) would be too short — clamp down to 4/3.
      expect(galleryAspectRatio(1920, 1080), closeTo(4 / 3, 1e-9));
    });
  });
}
