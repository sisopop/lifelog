import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _text(String id) =>
    addTextLayer(const PageCanvas(), id, 'hi').layers.single;

void main() {
  group('mirrorLayerX', () {
    test('reflects x across center, keeping other props', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(x: 0.2, y: 0.3, scale: 1.5, rotation: 20, z: 4),
      ]);
      final l = mirrorLayerX(base, 'a').layers.single;
      expect(l.x, closeTo(0.8, 1e-9));
      expect([l.y, l.scale, l.rotation, l.z], [0.3, 1.5, 20, 4]);
    });

    test('mirrors right side back to left', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.9)]);
      expect(mirrorLayerX(base, 'a').layers.single.x, closeTo(0.1, 1e-9));
    });

    test('already centered (x=0.5) returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.5)]);
      expect(identical(mirrorLayerX(base, 'a'), base), isTrue);
    });

    test('unknown id returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.2)]);
      expect(identical(mirrorLayerX(base, 'zzz'), base), isTrue);
    });

    test('only the target layer moves', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(x: 0.2),
        _text('b').copyWith(x: 0.3),
      ]);
      final out = mirrorLayerX(base, 'a');
      expect(out.layers.firstWhere((l) => l.id == 'a').x, closeTo(0.8, 1e-9));
      expect(out.layers.firstWhere((l) => l.id == 'b').x, 0.3);
    });

    test('applying twice returns to the original position', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.2)]);
      final twice = mirrorLayerX(mirrorLayerX(base, 'a'), 'a');
      expect(twice.layers.single.x, closeTo(0.2, 1e-9));
    });

    test('does not mutate the original', () {
      final base = PageCanvas(layers: [_text('a').copyWith(x: 0.2)]);
      mirrorLayerX(base, 'a');
      expect(base.layers.single.x, 0.2);
    });
  });
}
