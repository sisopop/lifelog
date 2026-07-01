import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 요약에 속지 무늬/바탕색을 더한
// 새 테스트는 여기에 둔다.
DecoLayer _sticker(String id) =>
    DecoLayer(id: id, kind: DecoKind.sticker, value: '🌸');

void main() {
  group('pageCanvasSummary paper', () {
    test('prepends the pattern label before layer counts', () {
      final canvas = PageCanvas(
        paper: PaperStyle.dotted,
        layers: [_sticker('a')],
      );
      expect(pageCanvasSummary(canvas), '도트 속지 · 스티커 1');
    });

    test('each pattern gets its own label', () {
      expect(
        pageCanvasSummary(const PageCanvas(paper: PaperStyle.lined)),
        '줄 속지',
      );
      expect(
        pageCanvasSummary(const PageCanvas(paper: PaperStyle.grid)),
        '모눈 속지',
      );
      expect(
        pageCanvasSummary(const PageCanvas(paper: PaperStyle.dotted)),
        '도트 속지',
      );
    });

    test('plain paper adds no prefix (byte-compatible with old summaries)', () {
      final canvas = PageCanvas(layers: [_sticker('a')]);
      expect(pageCanvasSummary(canvas), '스티커 1');
    });

    test('custom background color is noted', () {
      const canvas = PageCanvas(paperColorValue: 0xFFFFC0CB);
      expect(pageCanvasSummary(canvas), '바탕색');
    });

    test('pattern, background color and layers combine in order', () {
      final canvas = PageCanvas(
        paper: PaperStyle.grid,
        paperColorValue: 0xFFB2EBF2,
        layers: [_sticker('a')],
      );
      expect(pageCanvasSummary(canvas), '모눈 속지 · 바탕색 · 스티커 1');
    });

    test('still null when truly blank', () {
      expect(pageCanvasSummary(const PageCanvas()), isNull);
    });
  });
}
