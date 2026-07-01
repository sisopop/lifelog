import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker}) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('stepLayerOpacity', () {
    test('decreases opacity, keeps position/scale/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.2, y: 0.3, scale: 1.4, rotation: 20, z: 5),
      ]);
      final l = stepLayerOpacity(base, 'a', -0.2).layers.single;
      expect(l.opacity, closeTo(0.8, 1e-9));
      expect([l.x, l.y, l.scale, l.rotation, l.z], [0.2, 0.3, 1.4, 20, 5]);
    });

    test('increases opacity back up', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(opacity: 0.6)]);
      expect(stepLayerOpacity(base, 'a', 0.2).layers.single.opacity,
          closeTo(0.8, 1e-9));
    });

    test('clamps at the 0.2 floor', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(opacity: 0.3)]);
      expect(stepLayerOpacity(base, 'a', -0.5).layers.single.opacity, 0.2);
    });

    test('clamps at the 1.0 ceiling', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(opacity: 0.9)]);
      expect(stepLayerOpacity(base, 'a', 0.5).layers.single.opacity, 1.0);
    });

    test('already at floor → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(opacity: 0.2)]);
      expect(identical(stepLayerOpacity(base, 'a', -0.2), base), isTrue);
    });

    test('already at ceiling → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a')]); // 기본 opacity 1.0
      expect(identical(stepLayerOpacity(base, 'a', 0.2), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(opacity: 0.5)]);
      expect(identical(stepLayerOpacity(base, 'zzz', -0.2), base), isTrue);
    });

    test('only steps the target, leaves others put', () {
      final base = PageCanvas(layers: [
        _layer('a'),
        _layer('b').copyWith(opacity: 0.5),
      ]);
      final next = stepLayerOpacity(base, 'a', -0.2);
      expect(next.layers.firstWhere((l) => l.id == 'a').opacity,
          closeTo(0.8, 1e-9));
      expect(next.layers.firstWhere((l) => l.id == 'b').opacity, 0.5);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a')]);
      stepLayerOpacity(base, 'a', -0.2);
      expect(base.layers.single.opacity, 1.0);
    });
  });

  group('opacity serialization', () {
    test('omitted from toJson when 1.0 (byte-compatible with old data)', () {
      expect(_layer('a').toJson().containsKey('opacity'), isFalse);
    });

    test('emitted and round-trips when reduced', () {
      final json = _layer('a').copyWith(opacity: 0.6).toJson();
      expect(json['opacity'], closeTo(0.6, 1e-9));
      expect(DecoLayer.fromJson(json).opacity, closeTo(0.6, 1e-9));
    });

    test('missing opacity defaults to 1.0 (old saves)', () {
      final l = DecoLayer.fromJson({'id': 'a', 'kind': 'sticker', 'value': '🌸'});
      expect(l.opacity, 1.0);
    });

    test('duplicateLayer copies opacity', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(opacity: 0.4)]);
      final dup = duplicateLayer(base, 'a', 'a2');
      expect(dup.layers.firstWhere((l) => l.id == 'a2').opacity,
          closeTo(0.4, 1e-9));
    });
  });
}
