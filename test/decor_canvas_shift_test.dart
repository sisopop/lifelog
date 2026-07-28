import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/decor_canvas_shift.dart';

void main() {
  group('decorCanvasEditShift', () {
    // 캔버스: top 8, 높이 500. 자판 위 공간 300, 편집바 56 → 목표선 y = 122.
    double shift(double boxCenterY) => decorCanvasEditShift(
          canvasTop: 8,
          canvasHeight: 500,
          boxCenterY: boxCenterY,
          viewportHeight: 300,
          barHeight: 56,
        );

    test('아래쪽 상자는 목표선까지 캔버스를 위로 민다', () {
      // 상자 중심 y = 8 + 0.5*500 = 258 → 258-122 = 136
      expect(shift(0.5), 136);
    });

    test('맨 아래 상자는 더 많이 민다', () {
      expect(shift(0.9), closeTo(336, 0.001)); // 8+450-122
    });

    test('이미 목표선보다 위에 있으면 밀지 않는다(0)', () {
      expect(shift(0.1), 0); // 8+50=58 < 122
      expect(shift(0.0), 0);
    });

    test('캔버스 높이보다 많이 밀지 않는다', () {
      expect(
        decorCanvasEditShift(
          canvasTop: 8,
          canvasHeight: 100,
          boxCenterY: 1.0,
          viewportHeight: 20,
          barHeight: 0,
        ),
        98, // 108-10 = 98, 캔버스 높이(100) 이하라 클램프 없음
      );
      expect(
        decorCanvasEditShift(
          canvasTop: 500,
          canvasHeight: 100,
          boxCenterY: 1.0,
          viewportHeight: 20,
          barHeight: 0,
        ),
        100, // 600-10=590 → 캔버스 높이로 클램프
      );
    });

    test('편집바 기본값은 kDecorFormatBarHeight', () {
      expect(
        decorCanvasEditShift(
          canvasTop: 0,
          canvasHeight: 400,
          boxCenterY: 1.0,
          viewportHeight: 300,
        ),
        400 - (300 - kDecorFormatBarHeight) / 2,
      );
    });
  });
}
