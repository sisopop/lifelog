import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/core/utils/keyboard_edit.dart';
import 'package:lifelog/features/decorate/decor_canvas_shift.dart';

void main() {
  group('isKeyboardEditing', () {
    test('모바일: 포커스 + 자판 높이 > 0 이어야 편집 중', () {
      expect(isKeyboardEditing(hasFocus: true, keyboardHeight: 300), isTrue);
      expect(isKeyboardEditing(hasFocus: true, keyboardHeight: 0), isFalse);
      expect(isKeyboardEditing(hasFocus: false, keyboardHeight: 300), isFalse);
    });

    test('웹: 자판 높이를 보고하지 않으므로 포커스만으로 편집 중', () {
      expect(
        isKeyboardEditing(hasFocus: true, keyboardHeight: 0, isWeb: true),
        isTrue,
      );
      expect(
        isKeyboardEditing(hasFocus: false, keyboardHeight: 0, isWeb: true),
        isFalse,
      );
    });
  });

  group('isWebMobileViewport', () {
    test('웹 + 창이 짧으면 true(자판이 창을 줄인 모바일 브라우저)', () {
      expect(isWebMobileViewport(isWeb: true, viewportHeight: 400), isTrue);
    });

    test('웹이지만 창이 크면(PC 브라우저) false', () {
      expect(isWebMobileViewport(isWeb: true, viewportHeight: 1000), isFalse);
      expect(
        isWebMobileViewport(
          isWeb: true,
          viewportHeight: kWebMobileMaxHeight,
        ),
        isFalse,
      );
    });

    test('웹이 아니면 항상 false(자판 높이로 판단)', () {
      expect(isWebMobileViewport(isWeb: false, viewportHeight: 400), isFalse);
    });
  });

  group('decorCanvasBoxHidden', () {
    test('보이는 영역(뷰포트-편집바) 아래면 true', () {
      // 상자 중심 y = 8 + 0.9*500 = 458 > 300-56 = 244
      expect(
        decorCanvasBoxHidden(
          canvasTop: 8,
          canvasHeight: 500,
          boxCenterY: 0.9,
          viewportHeight: 300,
        ),
        isTrue,
      );
    });

    test('보이는 영역 안이면 false', () {
      // 8 + 0.2*500 = 108 < 244
      expect(
        decorCanvasBoxHidden(
          canvasTop: 8,
          canvasHeight: 500,
          boxCenterY: 0.2,
          viewportHeight: 300,
        ),
        isFalse,
      );
    });

    test('편집바 기본값은 kDecorFormatBarHeight', () {
      // 경계: 중심 = viewportHeight - 56 이면 (같으므로) false
      expect(
        decorCanvasBoxHidden(
          canvasTop: 0,
          canvasHeight: 100,
          boxCenterY: 1.0,
          viewportHeight: 100 + kDecorFormatBarHeight,
        ),
        isFalse,
      );
    });
  });
}
