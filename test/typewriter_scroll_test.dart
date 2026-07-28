import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/write/body_rich_editor.dart';

void main() {
  group('typewriterScrollTarget', () {
    // 뷰포트 상단 100, 높이 300, 편집바 56 → 목표 y = 100 + (300-56)/2 = 222.
    double? t({
      required double caretY,
      double pixels = 0,
      double minExtent = 0,
      double maxExtent = 1000,
    }) =>
        typewriterScrollTarget(
          caretY: caretY,
          viewportTop: 100,
          viewportHeight: 300,
          barHeight: 56,
          pixels: pixels,
          minExtent: minExtent,
          maxExtent: maxExtent,
        );

    test('커서가 목표선보다 아래면 그만큼 더 스크롤한다', () {
      expect(t(caretY: 322, pixels: 40), 140); // 40 + (322-222)
    });

    test('커서가 목표선보다 위면 되돌려 스크롤한다', () {
      expect(t(caretY: 122, pixels: 200), 100); // 200 + (122-222)
    });

    test('이미 가운데면(2px 미만) null', () {
      expect(t(caretY: 222, pixels: 50), isNull);
      expect(t(caretY: 223, pixels: 50), isNull);
    });

    test('문서 끝에서는 maxExtent로 클램프', () {
      expect(t(caretY: 900, pixels: 100, maxExtent: 300), 300);
    });

    test('문서 처음에서는 minExtent로 클램프(음수 스크롤 없음)', () {
      expect(t(caretY: 0, pixels: 10), 0);
    });

    test('편집바가 없으면 목표선이 뷰포트 정중앙', () {
      expect(
        typewriterScrollTarget(
          caretY: 300,
          viewportTop: 100,
          viewportHeight: 300,
          barHeight: 0,
          pixels: 0,
          minExtent: 0,
          maxExtent: 1000,
        ),
        50, // 목표 y = 250
      );
    });
  });
}
