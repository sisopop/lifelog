import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _text(String id) =>
    addTextLayer(const PageCanvas(), id, 'hi').layers.single;

void main() {
  group('mirrorLayerY', () {
    test('reflects y across center, keeping other props', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(x: 0.3, y: 0.2, scale: 1.5, rotation: 20, z: 4),
      ]);
      final l = mirrorLayerY(base, 'a').layers.single;
      expect(l.y, closeTo(0.8, 1e-9));
      expect([l.x, l.scale, l.rotation, l.z], [0.3, 1.5, 20, 4]);
    });

    test('mirrors bottom back to top', () {
      final base = PageCanvas(layers: [_text('a').copyWith(y: 0.9)]);
      expect(mirrorLayerY(base, 'a').layers.single.y, closeTo(0.1, 1e-9));
    });

    test('already centered (y=0.5) returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(y: 0.5)]);
      expect(identical(mirrorLayerY(base, 'a'), base), isTrue);
    });

    test('unknown id returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(y: 0.2)]);
      expect(identical(mirrorLayerY(base, 'zzz'), base), isTrue);
    });

    test('only the target layer moves', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(y: 0.2),
        _text('b').copyWith(y: 0.3),
      ]);
      final out = mirrorLayerY(base, 'a');
      expect(out.layers.firstWhere((l) => l.id == 'a').y, closeTo(0.8, 1e-9));
      expect(out.layers.firstWhere((l) => l.id == 'b').y, 0.3);
    });

    test('applying twice returns to the original position', () {
      final base = PageCanvas(layers: [_text('a').copyWith(y: 0.2)]);
      final twice = mirrorLayerY(mirrorLayerY(base, 'a'), 'a');
      expect(twice.layers.single.y, closeTo(0.2, 1e-9));
    });

    test('does not mutate the original', () {
      final base = PageCanvas(layers: [_text('a').copyWith(y: 0.2)]);
      mirrorLayerY(base, 'a');
      expect(base.layers.single.y, 0.2);
    });
  });
}
