import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 미세 이동(nudge) 테스트는 여기 둔다.
DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker}) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('nudgeLayer', () {
    test('moves by dx/dy, keeps scale/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.5, y: 0.5, scale: 1.6, rotation: 30, z: 4),
      ]);
      final l = nudgeLayer(base, 'a', 0.1, -0.2).layers.single;
      expect(l.x, closeTo(0.6, 1e-9));
      expect(l.y, closeTo(0.3, 1e-9));
      expect([l.scale, l.rotation, l.z], [1.6, 30, 4]);
    });

    test('clamps at the upper edge (1.0)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.95, y: 0.95)]);
      final l = nudgeLayer(base, 'a', 0.2, 0.2).layers.single;
      expect([l.x, l.y], [1.0, 1.0]);
    });

    test('clamps at the lower edge (0.0)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.05, y: 0.05)]);
      final l = nudgeLayer(base, 'a', -0.2, -0.2).layers.single;
      expect([l.x, l.y], [0.0, 0.0]);
    });

    test('already at edge, pushing further → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 1.0, y: 0.5)]);
      expect(identical(nudgeLayer(base, 'a', 0.1, 0.0), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.2)]);
      expect(identical(nudgeLayer(base, 'zzz', 0.1, 0.1), base), isTrue);
    });

    test('only moves the target, leaves others put', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.5, y: 0.5),
        _layer('b').copyWith(x: 0.2, y: 0.2),
      ]);
      final next = nudgeLayer(base, 'a', 0.1, 0.0);
      final a = next.layers.firstWhere((l) => l.id == 'a');
      final b = next.layers.firstWhere((l) => l.id == 'b');
      expect(a.x, closeTo(0.6, 1e-9));
      expect([b.x, b.y], [0.2, 0.2]);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.5, y: 0.5)]);
      nudgeLayer(base, 'a', 0.1, 0.1);
      expect([base.layers.single.x, base.layers.single.y], [0.5, 0.5]);
    });
  });
}
