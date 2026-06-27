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

  group('coverIconPalette', () {
    test('중복이 없다', () {
      expect(coverIconPalette.toSet().length, coverIconPalette.length);
    });

    test('"없음" 센티넬은 빈 문자열이라 프리셋에 안 들어간다', () {
      expect(kNoCoverIcon, '');
      expect(coverIconPalette, isNot(contains(kNoCoverIcon)));
    });
  });

  group('coverIconPaletteFor', () {
    test('항상 맨 앞에 "없음"(빈 문자열)을 끼운다', () {
      final result = coverIconPaletteFor(coverIconPalette.first);
      expect(result.first, kNoCoverIcon);
      expect(result, [kNoCoverIcon, ...coverIconPalette]);
      expect(result.toSet().length, result.length);
    });

    test('현재 아이콘이 "없음"이면 없음 다음에 프리셋이 온다', () {
      final result = coverIconPaletteFor(kNoCoverIcon);
      expect(result, [kNoCoverIcon, ...coverIconPalette]);
    });

    test('현재 아이콘이 프리셋에 없으면 없음 다음에 끼워 넣는다', () {
      const custom = '🦄';
      final result = coverIconPaletteFor(custom);
      expect(result.first, kNoCoverIcon);
      expect(result[1], custom);
      expect(result.length, coverIconPalette.length + 2);
      expect(result.toSet().length, result.length);
    });
  });
}
