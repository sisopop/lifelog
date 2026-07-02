import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 크기 단계 조절 테스트는 여기 둔다.
DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker}) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('stepLayerScale', () {
    test('grows by delta, keeps position/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.2, y: 0.3, scale: 1.0, rotation: 20, z: 4),
      ]);
      final l = stepLayerScale(base, 'a', 0.15).layers.single;
      expect(l.scale, closeTo(1.15, 1e-9));
      expect([l.x, l.y, l.rotation, l.z], [0.2, 0.3, 20, 4]);
    });

    test('shrinks by a negative delta', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: 1.0)]);
      expect(stepLayerScale(base, 'a', -0.15).layers.single.scale,
          closeTo(0.85, 1e-9));
    });

    test('clamps at the maximum (kMaxLayerScale)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: 3.95)]);
      expect(stepLayerScale(base, 'a', 0.5).layers.single.scale, kMaxLayerScale);
    });

    test('clamps at the minimum (kMinLayerScale)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: 0.45)]);
      expect(stepLayerScale(base, 'a', -0.5).layers.single.scale, kMinLayerScale);
    });

    test('already at the limit, pushing further → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: kMaxLayerScale)]);
      expect(identical(stepLayerScale(base, 'a', 0.15), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: 1.0)]);
      expect(identical(stepLayerScale(base, 'zzz', 0.15), base), isTrue);
    });

    test('only scales the target, leaves others put', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(scale: 1.0),
        _layer('b').copyWith(scale: 2.0),
      ]);
      final next = stepLayerScale(base, 'a', 0.15);
      expect(next.layers.firstWhere((l) => l.id == 'a').scale, closeTo(1.15, 1e-9));
      expect(next.layers.firstWhere((l) => l.id == 'b').scale, 2.0);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: 1.0)]);
      stepLayerScale(base, 'a', 0.15);
      expect(base.layers.single.scale, 1.0);
    });
  });
}
