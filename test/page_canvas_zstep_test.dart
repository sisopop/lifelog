import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, "한 칸 앞/뒤" z 이동 테스트는 여기 둔다.
DecoLayer _layer(String id, {int z = 0}) =>
    DecoLayer(id: id, kind: DecoKind.sticker, value: '🌸', z: z);

// 정렬 뒤 id 순서(아래→위)를 뽑아 비교하기 쉽게.
List<String> _order(PageCanvas c) => layersByZ(c).map((l) => l.id).toList();

void main() {
  group('stepLayerForward', () {
    test('swaps z with the layer just above (one step up)', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 0),
        _layer('b', z: 1),
        _layer('c', z: 2),
      ]);
      // a[0] b[1] c[2] → a를 한 칸 위로 → b a c
      expect(_order(stepLayerForward(base, 'a')), ['b', 'a', 'c']);
    });

    test('a second step moves it up once more', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 0),
        _layer('b', z: 1),
        _layer('c', z: 2),
      ]);
      final once = stepLayerForward(base, 'a'); // b a c
      expect(_order(stepLayerForward(once, 'a')), ['b', 'c', 'a']);
    });

    test('top layer stays put (same instance)', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      expect(identical(stepLayerForward(base, 'b'), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      expect(identical(stepLayerForward(base, 'zzz'), base), isTrue);
    });

    test('keeps every layer, just reorders', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 0),
        _layer('b', z: 1),
        _layer('c', z: 2),
      ]);
      final next = stepLayerForward(base, 'a');
      expect(next.layers.length, 3);
      expect(next.layers.map((l) => l.id).toSet(), {'a', 'b', 'c'});
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      stepLayerForward(base, 'a');
      expect(_order(base), ['a', 'b']);
    });
  });

  group('stepLayerBackward', () {
    test('swaps z with the layer just below (one step down)', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 0),
        _layer('b', z: 1),
        _layer('c', z: 2),
      ]);
      // c를 한 칸 아래로 → a c b
      expect(_order(stepLayerBackward(base, 'c')), ['a', 'c', 'b']);
    });

    test('bottom layer stays put (same instance)', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      expect(identical(stepLayerBackward(base, 'a'), base), isTrue);
    });

    test('unknown id → unchanged (same instance)', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      expect(identical(stepLayerBackward(base, 'zzz'), base), isTrue);
    });

    test('forward then backward returns to the original order', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 0),
        _layer('b', z: 1),
        _layer('c', z: 2),
      ]);
      final back = stepLayerBackward(stepLayerForward(base, 'a'), 'a');
      expect(_order(back), ['a', 'b', 'c']);
    });

    test('does not mutate original', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      stepLayerBackward(base, 'b');
      expect(_order(base), ['a', 'b']);
    });
  });
}
