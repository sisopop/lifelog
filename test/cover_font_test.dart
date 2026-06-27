import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_font.dart';

void main() {
  group('coverFontPalette', () {
    test('첫 항목은 기본(Pretendard)이고 family가 null이다', () {
      expect(coverFontPalette.first.id, kDefaultCoverFont);
      expect(coverFontPalette.first.family, isNull);
    });

    test('id에 중복이 없다', () {
      final ids = coverFontPalette.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('coverFontFamily', () {
    test('기본 글꼴은 null을 돌려준다(테마 글꼴 사용)', () {
      expect(coverFontFamily(kDefaultCoverFont), isNull);
    });

    test('프리셋 글꼴은 해당 fontFamily를 돌려준다', () {
      expect(coverFontFamily('jua'), 'Jua');
      expect(coverFontFamily('dohyeon'), 'DoHyeon');
      expect(coverFontFamily('gaegu'), 'Gaegu');
    });

    test('알 수 없는 id는 null(기본)로 폴백한다', () {
      expect(coverFontFamily('bogus'), isNull);
    });
  });

  group('normalizeCoverFont', () {
    test('알려진 id는 그대로 둔다', () {
      expect(normalizeCoverFont('jua'), 'jua');
    });

    test('알 수 없는 id는 기본으로 폴백한다', () {
      expect(normalizeCoverFont('bogus'), kDefaultCoverFont);
      expect(normalizeCoverFont(''), kDefaultCoverFont);
    });
  });

  group('coverFontLabel', () {
    test('프리셋 라벨을 돌려준다', () {
      expect(coverFontLabel(kDefaultCoverFont), '기본');
      expect(coverFontLabel('gaegu'), '손글씨');
    });

    test('알 수 없는 id는 기본 라벨로 폴백한다', () {
      expect(coverFontLabel('bogus'), '기본');
    });
  });
}
