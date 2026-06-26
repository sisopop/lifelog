import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_ribbon.dart';

void main() {
  group('normalizeCoverRibbon', () {
    test('null은 none으로 정규화한다', () {
      expect(normalizeCoverRibbon(null), kDefaultCoverRibbon);
    });

    test('알 수 없는 id는 none으로 정규화한다', () {
      expect(normalizeCoverRibbon('neon-laser'), kDefaultCoverRibbon);
    });

    test('유효한 id는 그대로 반환한다', () {
      expect(normalizeCoverRibbon('red'), 'red');
      expect(normalizeCoverRibbon('gold'), 'gold');
      expect(normalizeCoverRibbon('pink'), 'pink');
    });
  });

  group('coverRibbonPalette', () {
    test('none이 맨 앞에 있다', () {
      expect(coverRibbonPalette.first, kDefaultCoverRibbon);
    });

    test('중복이 없다', () {
      expect(coverRibbonPalette.toSet().length, coverRibbonPalette.length);
    });

    test('모든 리본에 한글 라벨이 있다', () {
      for (final id in coverRibbonPalette) {
        expect(coverRibbonLabels.containsKey(id), isTrue, reason: id);
      }
    });

    test('none을 제외한 모든 리본에 색상이 있다', () {
      for (final id in coverRibbonPalette) {
        if (id == kDefaultCoverRibbon) continue;
        expect(coverRibbonColors.containsKey(id), isTrue, reason: id);
      }
    });

    test('none에는 색상이 없다', () {
      expect(coverRibbonColors.containsKey(kDefaultCoverRibbon), isFalse);
    });
  });

  group('coverRibbonLabel', () {
    test('알려진 id는 한글 라벨을 반환한다', () {
      expect(coverRibbonLabel('none'), '없음');
      expect(coverRibbonLabel('gold'), '골드');
    });

    test('알 수 없는 id는 id를 그대로 반환한다', () {
      expect(coverRibbonLabel('zzz'), 'zzz');
    });
  });
}
