import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _text(String id) =>
    addTextLayer(const PageCanvas(), id, 'hi').layers.single;

void main() {
  group('snapLayerToGrid', () {
    test('rounds x,y to nearest 0.1, keeping other props', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(x: 0.23, y: 0.27, scale: 1.5, rotation: 20, z: 4),
      ]);
      final l = snapLayerToGrid(base, 'a').layers.single;
      expect(l.x, closeTo(0.2, 1e-9));
      expect(l.y, closeTo(0.3, 1e-9));
      expect([l.scale, l.rotation, l.z], [1.5, 20, 4]);
    });

    test('rounds halves up', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.65, y: 0.15)]);
      final l = snapLayerToGrid(base, 'a').layers.single;
      expect(l.x, closeTo(0.7, 1e-9));
      expect(l.y, closeTo(0.2, 1e-9));
    });

    test('already on the grid returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.3, y: 0.5)]);
      expect(identical(snapLayerToGrid(base, 'a'), base), isTrue);
    });

    test('unknown id returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.23, y: 0.27)]);
      expect(identical(snapLayerToGrid(base, 'zzz'), base), isTrue);
    });

    test('stays within 0..1 bounds', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.98, y: 0.02)]);
      final l = snapLayerToGrid(base, 'a').layers.single;
      expect(l.x, closeTo(1.0, 1e-9));
      expect(l.y, closeTo(0.0, 1e-9));
    });

    test('only the target layer moves', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(x: 0.23, y: 0.27),
        _text('b').copyWith(x: 0.34, y: 0.31),
      ]);
      final out = snapLayerToGrid(base, 'a');
      final b = out.layers.firstWhere((l) => l.id == 'b');
      expect([b.x, b.y], [0.34, 0.31]);
    });

    test('idempotent — snapping twice equals snapping once', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.23, y: 0.27)]);
      final once = snapLayerToGrid(base, 'a');
      expect(identical(snapLayerToGrid(once, 'a'), once), isTrue);
    });

    test('does not mutate the original', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.23, y: 0.27)]);
      snapLayerToGrid(base, 'a');
      expect([base.layers.single.x, base.layers.single.y], [0.23, 0.27]);
    });
  });
}
