import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _text(String id) =>
    addTextLayer(const PageCanvas(), id, 'hi').layers.single;

void main() {
  group('mirrorLayerPoint', () {
    test('reflects both axes through center, keeping other props', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(x: 0.2, y: 0.3, scale: 1.5, rotation: 20, z: 4),
      ]);
      final l = mirrorLayerPoint(base, 'a').layers.single;
      expect(l.x, closeTo(0.8, 1e-9));
      expect(l.y, closeTo(0.7, 1e-9));
      expect([l.scale, l.rotation, l.z], [1.5, 20, 4]);
    });

    test('equals applying mirrorLayerX then mirrorLayerY', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.1, y: 0.25)]);
      final chained = mirrorLayerY(mirrorLayerX(base, 'a'), 'a').layers.single;
      final point = mirrorLayerPoint(base, 'a').layers.single;
      expect(point.x, closeTo(chained.x, 1e-9));
      expect(point.y, closeTo(chained.y, 1e-9));
    });

    test('already dead center (0.5,0.5) returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.5, y: 0.5)]);
      expect(identical(mirrorLayerPoint(base, 'a'), base), isTrue);
    });

    test('centered on one axis only still moves', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.5, y: 0.2)]);
      final l = mirrorLayerPoint(base, 'a').layers.single;
      expect(l.x, closeTo(0.5, 1e-9));
      expect(l.y, closeTo(0.8, 1e-9));
    });

    test('unknown id returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.2, y: 0.3)]);
      expect(identical(mirrorLayerPoint(base, 'zzz'), base), isTrue);
    });

    test('only the target layer moves', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(x: 0.2, y: 0.2),
        _text('b').copyWith(x: 0.3, y: 0.3),
      ]);
      final out = mirrorLayerPoint(base, 'a');
      final a = out.layers.firstWhere((l) => l.id == 'a');
      final b = out.layers.firstWhere((l) => l.id == 'b');
      expect([a.x, a.y], [closeTo(0.8, 1e-9), closeTo(0.8, 1e-9)]);
      expect([b.x, b.y], [0.3, 0.3]);
    });

    test('applying twice returns to the original position', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.2, y: 0.3)]);
      final twice = mirrorLayerPoint(mirrorLayerPoint(base, 'a'), 'a');
      expect(twice.layers.single.x, closeTo(0.2, 1e-9));
      expect(twice.layers.single.y, closeTo(0.3, 1e-9));
    });

    test('does not mutate the original', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.2, y: 0.3)]);
      mirrorLayerPoint(base, 'a');
      expect([base.layers.single.x, base.layers.single.y], [0.2, 0.3]);
    });
  });
}
