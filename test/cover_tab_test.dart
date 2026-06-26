import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_tab.dart';

void main() {
  group('normalizeCoverTab', () {
    test('null은 none으로 정규화한다', () {
      expect(normalizeCoverTab(null), kDefaultCoverTab);
    });

    test('알 수 없는 id는 none으로 정규화한다', () {
      expect(normalizeCoverTab('rainbow-monster'), kDefaultCoverTab);
    });

    test('유효한 id는 그대로 반환한다', () {
      expect(normalizeCoverTab('colorful'), 'colorful');
      expect(normalizeCoverTab('pink'), 'pink');
      expect(normalizeCoverTab('blue'), 'blue');
    });
  });

  group('coverTabPalette', () {
    test('none이 맨 앞에 있다', () {
      expect(coverTabPalette.first, kDefaultCoverTab);
    });

    test('중복이 없다', () {
      expect(coverTabPalette.toSet().length, coverTabPalette.length);
    });

    test('모든 탭에 한글 라벨이 있다', () {
      for (final id in coverTabPalette) {
        expect(coverTabLabels.containsKey(id), isTrue, reason: id);
      }
    });
  });

  group('coverTabLabel', () {
    test('알려진 id는 한글 라벨을 반환한다', () {
      expect(coverTabLabel('none'), '없음');
      expect(coverTabLabel('colorful'), '컬러풀');
      expect(coverTabLabel('pink'), '핑크');
      expect(coverTabLabel('blue'), '블루');
    });

    test('알 수 없는 id는 id를 그대로 반환한다', () {
      expect(coverTabLabel('zzz'), 'zzz');
    });
  });
}
