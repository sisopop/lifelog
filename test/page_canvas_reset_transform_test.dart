import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 변형 초기화 테스트는 여기 둔다.
DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker}) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('resetLayerTransform', () {
    test('resets scale/rotation/flip/opacity, keeps position/z/text props', () {
      final base = PageCanvas(layers: [
        _layer('a', kind: DecoKind.text).copyWith(
          x: 0.2,
          y: 0.3,
          z: 4,
          scale: 2.5,
          rotation: 40,
          flipX: true,
          flipY: true,
          opacity: 0.4,
          colorValue: 0xFF112233,
          bold: true,
        ),
      ]);
      final l = resetLayerTransform(base, 'a').layers.single;
      expect([l.scale, l.rotation, l.opacity], [1.0, 0.0, 1.0]);
      expect([l.flipX, l.flipY], [false, false]);
      // 위치·z·글자 속성은 보존
      expect([l.x, l.y, l.z], [0.2, 0.3, 4]);
      expect([l.colorValue, l.bold], [0xFF112233, true]);
    });

    test('resets even when only one transform is off default', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(rotation: 15)]);
      expect(resetLayerTransform(base, 'a').layers.single.rotation, 0.0);
    });

    test('all transforms already default → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a')]); // scale1/rot0/flip无/op1
      expect(identical(resetLayerTransform(base, 'a'), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(scale: 2.0)]);
      expect(identical(resetLayerTransform(base, 'zzz'), base), isTrue);
    });

    test('only resets the target, leaves others put', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(scale: 2.0, rotation: 30),
        _layer('b').copyWith(scale: 3.0, opacity: 0.5),
      ]);
      final next = resetLayerTransform(base, 'a');
      final a = next.layers.firstWhere((l) => l.id == 'a');
      final b = next.layers.firstWhere((l) => l.id == 'b');
      expect([a.scale, a.rotation], [1.0, 0.0]);
      expect([b.scale, b.opacity], [3.0, 0.5]);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(scale: 2.0, flipX: true, opacity: 0.3),
      ]);
      resetLayerTransform(base, 'a');
      final o = base.layers.single;
      expect([o.scale, o.flipX, o.opacity], [2.0, true, 0.3]);
    });
  });
}
