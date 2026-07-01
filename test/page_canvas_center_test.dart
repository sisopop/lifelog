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

  group('resetLayerScale', () {
    test('resets scale to 1.0, keeps position/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.2, y: 0.3, scale: 2.5, rotation: 20, z: 4),
      ]);
      final l = resetLayerScale(base, 'a').layers.single;
      expect(l.scale, 1.0);
      expect([l.x, l.y, l.rotation, l.z], [0.2, 0.3, 20, 4]);
    });

    test('already default scale → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a')]); // 기본 scale = 1.0
      expect(identical(resetLayerScale(base, 'a'), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: 2.0)]);
      expect(identical(resetLayerScale(base, 'zzz'), base), isTrue);
    });

    test('only resets the target, leaves others put', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(scale: 2.0),
        _layer('b').copyWith(scale: 3.0),
      ]);
      final next = resetLayerScale(base, 'a');
      expect(next.layers.firstWhere((l) => l.id == 'a').scale, 1.0);
      expect(next.layers.firstWhere((l) => l.id == 'b').scale, 3.0);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: 2.0)]);
      resetLayerScale(base, 'a');
      expect(base.layers.single.scale, 2.0);
    });
  });

  group('centerLayerHorizontally', () {
    test('sets x to 0.5, keeps y/scale/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.1, y: 0.8, scale: 1.6, rotation: 30, z: 4),
      ]);
      final l = centerLayerHorizontally(base, 'a').layers.single;
      expect(l.x, 0.5);
      expect([l.y, l.scale, l.rotation, l.z], [0.8, 1.6, 30, 4]);
    });

    test('already horizontally centered → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(y: 0.2)]); // x=0.5
      expect(identical(centerLayerHorizontally(base, 'a'), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.2)]);
      expect(identical(centerLayerHorizontally(base, 'zzz'), base), isTrue);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.2, y: 0.2)]);
      centerLayerHorizontally(base, 'a');
      expect([base.layers.single.x, base.layers.single.y], [0.2, 0.2]);
    });
  });

  group('centerLayerVertically', () {
    test('sets y to 0.5, keeps x/scale/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.8, y: 0.1, scale: 1.6, rotation: 30, z: 4),
      ]);
      final l = centerLayerVertically(base, 'a').layers.single;
      expect(l.y, 0.5);
      expect([l.x, l.scale, l.rotation, l.z], [0.8, 1.6, 30, 4]);
    });

    test('already vertically centered → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.2)]); // y=0.5
      expect(identical(centerLayerVertically(base, 'a'), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(y: 0.2)]);
      expect(identical(centerLayerVertically(base, 'zzz'), base), isTrue);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.2, y: 0.2)]);
      centerLayerVertically(base, 'a');
      expect([base.layers.single.x, base.layers.single.y], [0.2, 0.2]);
    });
  });
}
