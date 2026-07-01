import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker}) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('centerLayer', () {
    test('moves the layer to page center, keeps scale/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.1, y: 0.9, scale: 1.6, rotation: 30, z: 4),
      ]);
      final next = centerLayer(base, 'a');
      final l = next.layers.single;
      expect(l.x, 0.5);
      expect(l.y, 0.5);
      expect(l.scale, 1.6);
      expect(l.rotation, 30);
      expect(l.z, 4);
    });

    test('already centered → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a')]); // 기본 x/y = 0.5
      expect(identical(centerLayer(base, 'a'), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.2)]);
      expect(identical(centerLayer(base, 'zzz'), base), isTrue);
    });

    test('only centers the target, leaves others put', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.1, y: 0.1),
        _layer('b').copyWith(x: 0.9, y: 0.9),
      ]);
      final next = centerLayer(base, 'a');
      final a = next.layers.firstWhere((l) => l.id == 'a');
      final b = next.layers.firstWhere((l) => l.id == 'b');
      expect([a.x, a.y], [0.5, 0.5]);
      expect([b.x, b.y], [0.9, 0.9]);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.2, y: 0.2)]);
      centerLayer(base, 'a');
      expect([base.layers.single.x, base.layers.single.y], [0.2, 0.2]);
    });
  });
}
