import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_pattern.dart';

void main() {
  group('normalizeCoverPattern', () {
    test('null은 none으로 정규화한다', () {
      expect(normalizeCoverPattern(null), kNoCoverPattern);
    });

    test('알 수 없는 id는 none으로 정규화한다', () {
      expect(normalizeCoverPattern('sparkles'), kNoCoverPattern);
    });

    test('유효한 id는 그대로 반환한다', () {
      expect(normalizeCoverPattern('dots'), 'dots');
      expect(normalizeCoverPattern('hearts'), 'hearts');
    });
  });

  group('coverPatternPalette', () {
    test('none이 맨 앞에 있다', () {
      expect(coverPatternPalette.first, kNoCoverPattern);
    });

    test('중복이 없다', () {
      expect(coverPatternPalette.toSet().length, coverPatternPalette.length);
    });

    test('모든 패턴에 한글 라벨이 있다', () {
      for (final id in coverPatternPalette) {
        expect(coverPatternLabels.containsKey(id), isTrue, reason: id);
      }
    });
  });

  group('coverPatternLabel', () {
    test('알려진 id는 한글 라벨을 반환한다', () {
      expect(coverPatternLabel('none'), '없음');
      expect(coverPatternLabel('grid'), '모눈');
    });

    test('알 수 없는 id는 id를 그대로 반환한다', () {
      expect(coverPatternLabel('xyz'), 'xyz');
    });
  });
}
