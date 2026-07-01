import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker}) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('rotateLayerQuarter', () {
    test('adds 90° clockwise, keeps position/scale/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.2, y: 0.3, scale: 1.4, rotation: 15, z: 5),
      ]);
      final l = rotateLayerQuarter(base, 'a').layers.single;
      expect(l.rotation, 105);
      expect([l.x, l.y, l.scale, l.z], [0.2, 0.3, 1.4, 5]);
    });

    test('wraps past 360° back into 0~359 range', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(rotation: 300)]);
      expect(rotateLayerQuarter(base, 'a').layers.single.rotation, 30);
    });

    test('normalizes a negative start angle', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(rotation: -8)]);
      expect(rotateLayerQuarter(base, 'a').layers.single.rotation, 82);
    });

    test('four quarter turns return to the original angle', () {
      var canvas = PageCanvas(layers: [_layer('a').copyWith(rotation: 0)]);
      for (var i = 0; i < 4; i++) {
        canvas = rotateLayerQuarter(canvas, 'a');
      }
      expect(canvas.layers.single.rotation, 0);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a')]);
      expect(identical(rotateLayerQuarter(base, 'zzz'), base), isTrue);
    });

    test('only rotates the target, leaves others put', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(rotation: 0),
        _layer('b').copyWith(rotation: 45),
      ]);
      final next = rotateLayerQuarter(base, 'a');
      expect(next.layers.firstWhere((l) => l.id == 'a').rotation, 90);
      expect(next.layers.firstWhere((l) => l.id == 'b').rotation, 45);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(rotation: 10)]);
      rotateLayerQuarter(base, 'a');
      expect(base.layers.single.rotation, 10);
    });
  });
}
