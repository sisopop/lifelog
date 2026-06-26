import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_band.dart';

void main() {
  group('normalizeCoverBand', () {
    test('null은 none으로 정규화한다', () {
      expect(normalizeCoverBand(null), kDefaultCoverBand);
    });

    test('알 수 없는 id는 none으로 정규화한다', () {
      expect(normalizeCoverBand('rubber-rocket'), kDefaultCoverBand);
    });

    test('유효한 id는 그대로 반환한다', () {
      expect(normalizeCoverBand('band'), 'band');
      expect(normalizeCoverBand('buckle'), 'buckle');
      expect(normalizeCoverBand('double'), 'double');
    });
  });

  group('coverBandPalette', () {
    test('none이 맨 앞에 있다', () {
      expect(coverBandPalette.first, kDefaultCoverBand);
    });

    test('중복이 없다', () {
      expect(coverBandPalette.toSet().length, coverBandPalette.length);
    });

    test('모든 밴드에 한글 라벨이 있다', () {
      for (final id in coverBandPalette) {
        expect(coverBandLabels.containsKey(id), isTrue, reason: id);
      }
    });
  });

  group('coverBandLabel', () {
    test('알려진 id는 한글 라벨을 반환한다', () {
      expect(coverBandLabel('none'), '없음');
      expect(coverBandLabel('buckle'), '버클');
    });

    test('알 수 없는 id는 id를 그대로 반환한다', () {
      expect(coverBandLabel('zzz'), 'zzz');
    });
  });
}
