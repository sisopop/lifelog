import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_corner.dart';

void main() {
  group('normalizeCoverCorner', () {
    test('null은 none으로 정규화한다', () {
      expect(normalizeCoverCorner(null), kDefaultCoverCorner);
    });

    test('알 수 없는 id는 none으로 정규화한다', () {
      expect(normalizeCoverCorner('sparkle-bomb'), kDefaultCoverCorner);
    });

    test('유효한 id는 그대로 반환한다', () {
      expect(normalizeCoverCorner('photo'), 'photo');
      expect(normalizeCoverCorner('tape'), 'tape');
      expect(normalizeCoverCorner('fold'), 'fold');
    });
  });

  group('coverCornerPalette', () {
    test('none이 맨 앞에 있다', () {
      expect(coverCornerPalette.first, kDefaultCoverCorner);
    });

    test('중복이 없다', () {
      expect(coverCornerPalette.toSet().length, coverCornerPalette.length);
    });

    test('모든 장식에 한글 라벨이 있다', () {
      for (final id in coverCornerPalette) {
        expect(coverCornerLabels.containsKey(id), isTrue, reason: id);
      }
    });
  });

  group('coverCornerLabel', () {
    test('알려진 id는 한글 라벨을 반환한다', () {
      expect(coverCornerLabel('none'), '없음');
      expect(coverCornerLabel('photo'), '포토');
    });

    test('알 수 없는 id는 id를 그대로 반환한다', () {
      expect(coverCornerLabel('zzz'), 'zzz');
    });
  });
}
