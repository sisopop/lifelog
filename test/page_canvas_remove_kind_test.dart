import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 종류 일괄 제거 테스트는 여기 둔다.
DecoLayer _layer(String id, DecoKind kind) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('removeLayersOfKind', () {
    test('removes every layer of the given kind, keeps the rest', () {
      final base = PageCanvas(layers: [
        _layer('a', DecoKind.sticker),
        _layer('b', DecoKind.tape),
        _layer('c', DecoKind.sticker),
        _layer('d', DecoKind.photo),
      ]);
      final next = removeLayersOfKind(base, DecoKind.sticker);
      expect(next.layers.map((l) => l.id).toList(), ['b', 'd']);
    });

    test('no layer of that kind → unchanged (same instance)', () {
      final base = PageCanvas(layers: [
        _layer('a', DecoKind.sticker),
        _layer('b', DecoKind.photo),
      ]);
      expect(identical(removeLayersOfKind(base, DecoKind.tape), base), isTrue);
    });

    test('empty canvas → unchanged (same instance)', () {
      final base = PageCanvas(layers: const []);
      expect(identical(removeLayersOfKind(base, DecoKind.text), base), isTrue);
    });

    test('removing the only kind leaves no layers', () {
      final base = PageCanvas(layers: [
        _layer('a', DecoKind.tape),
        _layer('b', DecoKind.tape),
      ]);
      expect(removeLayersOfKind(base, DecoKind.tape).layers, isEmpty);
    });

    test('keeps paper style and background color', () {
      final base = PageCanvas(
        paper: PaperStyle.grid,
        paperColorValue: 0xFFCCEEFF,
        layers: [_layer('a', DecoKind.sticker), _layer('b', DecoKind.tape)],
      );
      final next = removeLayersOfKind(base, DecoKind.tape);
      expect(next.paper, PaperStyle.grid);
      expect(next.paperColorValue, 0xFFCCEEFF);
      expect(next.layers.single.id, 'a');
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [
        _layer('a', DecoKind.sticker),
        _layer('b', DecoKind.sticker),
      ]);
      removeLayersOfKind(base, DecoKind.sticker);
      expect(base.layers.length, 2);
    });
  });
}
