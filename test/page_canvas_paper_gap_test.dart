import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas_view.dart';

void main() {
  group('paperGapForWidth', () {
    test('scales the paper gap with canvas width (~12 columns)', () {
      expect(paperGapForWidth(120), 10); // 120 / 12
      expect(paperGapForWidth(240), 20);
    });

    test('detail-width converges on the legacy 28px gap', () {
      expect(paperGapForWidth(336), 28); // matches the old fixed value
    });

    test('clamps tiny thumbnails so the pattern never gets too dense', () {
      expect(paperGapForWidth(54), 6); // 54/12=4.5 -> clamped up to 6
      expect(paperGapForWidth(0), 6);
    });

    test('clamps very wide canvases so lines never get too sparse', () {
      expect(paperGapForWidth(1000), 34); // 1000/12=83.3 -> clamped to 34
    });
  });
}
