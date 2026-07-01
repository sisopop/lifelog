import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker}) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('flipLayerX', () {
    test('toggles flipX on, keeps position/scale/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.2, y: 0.3, scale: 1.4, rotation: 20, z: 5),
      ]);
      final next = flipLayerX(base, 'a');
      final l = next.layers.single;
      expect(l.flipX, isTrue);
      expect([l.x, l.y, l.scale, l.rotation, l.z], [0.2, 0.3, 1.4, 20, 5]);
    });

    test('toggles back off when already flipped', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(flipX: true)]);
      expect(flipLayerX(base, 'a').layers.single.flipX, isFalse);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a')]);
      expect(identical(flipLayerX(base, 'zzz'), base), isTrue);
    });

    test('only flips the target, leaves others put', () {
      final base = PageCanvas(layers: [_layer('a'), _layer('b')]);
      final next = flipLayerX(base, 'a');
      expect(next.layers.firstWhere((l) => l.id == 'a').flipX, isTrue);
      expect(next.layers.firstWhere((l) => l.id == 'b').flipX, isFalse);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a')]);
      flipLayerX(base, 'a');
      expect(base.layers.single.flipX, isFalse);
    });
  });

  group('flipLayerY', () {
    test('toggles flipY on, keeps position/scale/rotation/z and flipX', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(x: 0.2, y: 0.3, scale: 1.4, rotation: 20, z: 5, flipX: true),
      ]);
      final l = flipLayerY(base, 'a').layers.single;
      expect(l.flipY, isTrue);
      expect(l.flipX, isTrue);
      expect([l.x, l.y, l.scale, l.rotation, l.z], [0.2, 0.3, 1.4, 20, 5]);
    });

    test('toggles back off when already flipped', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(flipY: true)]);
      expect(flipLayerY(base, 'a').layers.single.flipY, isFalse);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a')]);
      expect(identical(flipLayerY(base, 'zzz'), base), isTrue);
    });

    test('only flips the target, leaves others put', () {
      final base = PageCanvas(layers: [_layer('a'), _layer('b')]);
      final next = flipLayerY(base, 'a');
      expect(next.layers.firstWhere((l) => l.id == 'a').flipY, isTrue);
      expect(next.layers.firstWhere((l) => l.id == 'b').flipY, isFalse);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a')]);
      flipLayerY(base, 'a');
      expect(base.layers.single.flipY, isFalse);
    });
  });

  group('flipY serialization', () {
    test('omitted from toJson when false (byte-compatible with old data)', () {
      expect(_layer('a').toJson().containsKey('flipY'), isFalse);
    });

    test('emitted and round-trips when true', () {
      final json = _layer('a').copyWith(flipY: true).toJson();
      expect(json['flipY'], true);
      expect(DecoLayer.fromJson(json).flipY, isTrue);
    });

    test('duplicateLayer copies flipY', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(flipY: true)]);
      final dup = duplicateLayer(base, 'a', 'a2');
      expect(dup.layers.firstWhere((l) => l.id == 'a2').flipY, isTrue);
    });
  });

  group('flipX serialization', () {
    test('omitted from toJson when false (byte-compatible with old data)', () {
      expect(_layer('a').toJson().containsKey('flipX'), isFalse);
    });

    test('emitted and round-trips when true', () {
      final json = _layer('a').copyWith(flipX: true).toJson();
      expect(json['flipX'], true);
      expect(DecoLayer.fromJson(json).flipX, isTrue);
    });

    test('duplicateLayer copies flipX', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(flipX: true)]);
      final dup = duplicateLayer(base, 'a', 'a2');
      expect(dup.layers.firstWhere((l) => l.id == 'a2').flipX, isTrue);
    });
  });
}
