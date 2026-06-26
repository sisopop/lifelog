import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_palette.dart';

void main() {
  group('coverColorPalette', () {
    test('모든 색이 불투명(alpha 0xFF)이다', () {
      for (final c in coverColorPalette) {
        expect((c >> 24) & 0xFF, 0xFF, reason: '색 0x${c.toRadixString(16)}');
      }
    });

    test('중복이 없다', () {
      expect(coverColorPalette.toSet().length, coverColorPalette.length);
    });

    test('기본 표지색을 포함한다', () {
      expect(coverColorPalette, contains(kDefaultCoverColor));
    });
  });

  group('coverPaletteFor', () {
    test('현재 색이 프리셋에 있으면 팔레트를 그대로 돌려준다', () {
      expect(coverPaletteFor(kDefaultCoverColor), coverColorPalette);
    });

    test('현재 색이 프리셋에 없으면 맨 앞에 끼워 넣는다', () {
      const custom = 0xFF123456;
      final result = coverPaletteFor(custom);
      expect(result.first, custom);
      expect(result.length, coverColorPalette.length + 1);
      expect(result, contains(custom));
    });

    test('결과에 중복이 없다', () {
      const custom = 0xFF123456;
      final result = coverPaletteFor(custom);
      expect(result.toSet().length, result.length);
    });
  });
}
