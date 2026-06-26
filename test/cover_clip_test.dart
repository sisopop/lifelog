import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_clip.dart';

void main() {
  group('normalizeCoverClip', () {
    test('null은 none으로 정규화한다', () {
      expect(normalizeCoverClip(null), kDefaultCoverClip);
    });

    test('알 수 없는 id는 none으로 정규화한다', () {
      expect(normalizeCoverClip('binder-monster'), kDefaultCoverClip);
    });

    test('유효한 id는 그대로 반환한다', () {
      expect(normalizeCoverClip('silver'), 'silver');
      expect(normalizeCoverClip('gold'), 'gold');
      expect(normalizeCoverClip('pink'), 'pink');
    });
  });

  group('coverClipPalette', () {
    test('none이 맨 앞에 있다', () {
      expect(coverClipPalette.first, kDefaultCoverClip);
    });

    test('중복이 없다', () {
      expect(coverClipPalette.toSet().length, coverClipPalette.length);
    });

    test('모든 클립에 한글 라벨이 있다', () {
      for (final id in coverClipPalette) {
        expect(coverClipLabels.containsKey(id), isTrue, reason: id);
      }
    });

    test('none을 제외한 모든 클립에 색상이 있다', () {
      for (final id in coverClipPalette) {
        if (id == kDefaultCoverClip) continue;
        expect(coverClipColors.containsKey(id), isTrue, reason: id);
      }
    });

    test('none에는 색상이 없다', () {
      expect(coverClipColors.containsKey(kDefaultCoverClip), isFalse);
    });
  });

  group('coverClipLabel', () {
    test('알려진 id는 한글 라벨을 반환한다', () {
      expect(coverClipLabel('none'), '없음');
      expect(coverClipLabel('silver'), '실버');
    });

    test('알 수 없는 id는 id를 그대로 반환한다', () {
      expect(coverClipLabel('zzz'), 'zzz');
    });
  });
}
