import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 투명도 리셋 테스트는 여기 둔다.
DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker}) =>
    DecoLayer(id: id, kind: kind, value: '🌸');

void main() {
  group('resetLayerOpacity', () {
    test('resets opacity to 1.0, keeps position/scale/rotation/z', () {
      final base = PageCanvas(layers: [
        _layer('a')
            .copyWith(x: 0.2, y: 0.3, scale: 2.0, rotation: 20, z: 4, opacity: 0.4),
      ]);
      final l = resetLayerOpacity(base, 'a').layers.single;
      expect(l.opacity, 1.0);
      expect([l.x, l.y, l.scale, l.rotation, l.z], [0.2, 0.3, 2.0, 20, 4]);
    });

    test('already fully opaque → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a')]); // 기본 opacity = 1.0
      expect(identical(resetLayerOpacity(base, 'a'), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(opacity: 0.5)]);
      expect(identical(resetLayerOpacity(base, 'zzz'), base), isTrue);
    });

    test('only resets the target, leaves others put', () {
      final base = PageCanvas(layers: [
        _layer('a').copyWith(opacity: 0.4),
        _layer('b').copyWith(opacity: 0.6),
      ]);
      final next = resetLayerOpacity(base, 'a');
      expect(next.layers.firstWhere((l) => l.id == 'a').opacity, 1.0);
      expect(next.layers.firstWhere((l) => l.id == 'b').opacity, 0.6);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(opacity: 0.4)]);
      resetLayerOpacity(base, 'a');
      expect(base.layers.single.opacity, 0.4);
    });
  });
}
