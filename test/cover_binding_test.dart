import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_binding.dart';

void main() {
  group('normalizeCoverBinding', () {
    test('null은 plain으로 정규화한다', () {
      expect(normalizeCoverBinding(null), kDefaultCoverBinding);
    });

    test('알 수 없는 id는 plain으로 정규화한다', () {
      expect(normalizeCoverBinding('coil-of-doom'), kDefaultCoverBinding);
    });

    test('유효한 id는 그대로 반환한다', () {
      expect(normalizeCoverBinding('spiral'), 'spiral');
      expect(normalizeCoverBinding('ring'), 'ring');
      expect(normalizeCoverBinding('stitch'), 'stitch');
    });
  });

  group('coverBindingPalette', () {
    test('plain이 맨 앞에 있다', () {
      expect(coverBindingPalette.first, kDefaultCoverBinding);
    });

    test('중복이 없다', () {
      expect(coverBindingPalette.toSet().length, coverBindingPalette.length);
    });

    test('모든 제본에 한글 라벨이 있다', () {
      for (final id in coverBindingPalette) {
        expect(coverBindingLabels.containsKey(id), isTrue, reason: id);
      }
    });
  });

  group('coverBindingLabel', () {
    test('알려진 id는 한글 라벨을 반환한다', () {
      expect(coverBindingLabel('plain'), '무선');
      expect(coverBindingLabel('spiral'), '스프링');
    });

    test('알 수 없는 id는 id를 그대로 반환한다', () {
      expect(coverBindingLabel('zzz'), 'zzz');
    });
  });
}
