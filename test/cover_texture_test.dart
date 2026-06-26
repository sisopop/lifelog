import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_texture.dart';

void main() {
  group('normalizeCoverTexture', () {
    test('null은 none으로 정규화한다', () {
      expect(normalizeCoverTexture(null), kDefaultCoverTexture);
    });

    test('알 수 없는 id는 none으로 정규화한다', () {
      expect(normalizeCoverTexture('velvet-monster'), kDefaultCoverTexture);
    });

    test('유효한 id는 그대로 반환한다', () {
      expect(normalizeCoverTexture('leather'), 'leather');
      expect(normalizeCoverTexture('kraft'), 'kraft');
      expect(normalizeCoverTexture('fabric'), 'fabric');
    });
  });

  group('coverTexturePalette', () {
    test('none이 맨 앞에 있다', () {
      expect(coverTexturePalette.first, kDefaultCoverTexture);
    });

    test('중복이 없다', () {
      expect(coverTexturePalette.toSet().length, coverTexturePalette.length);
    });

    test('모든 재질에 한글 라벨이 있다', () {
      for (final id in coverTexturePalette) {
        expect(coverTextureLabels.containsKey(id), isTrue, reason: id);
      }
    });
  });

  group('coverTextureLabel', () {
    test('알려진 id는 한글 라벨을 반환한다', () {
      expect(coverTextureLabel('none'), '없음');
      expect(coverTextureLabel('leather'), '가죽');
      expect(coverTextureLabel('kraft'), '크라프트');
      expect(coverTextureLabel('fabric'), '패브릭');
    });

    test('알 수 없는 id는 id를 그대로 반환한다', () {
      expect(coverTextureLabel('zzz'), 'zzz');
    });
  });
}
