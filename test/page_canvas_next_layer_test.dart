import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 선택 순회 테스트는 여기 둔다.
DecoLayer _layer(String id, {int z = 0}) =>
    DecoLayer(id: id, kind: DecoKind.sticker, value: '🌸', z: z);

void main() {
  group('nextLayerId', () {
    test('empty canvas → null', () {
      expect(nextLayerId(const PageCanvas(layers: []), 'a'), isNull);
    });

    test('null current → bottom (z min) layer', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      expect(nextLayerId(base, null), 'b');
    });

    test('unknown current → bottom (z min) layer', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
      ]);
      expect(nextLayerId(base, 'zzz'), 'b');
    });

    test('single layer → itself', () {
      final base = PageCanvas(layers: [_layer('a', z: 2)]);
      expect(nextLayerId(base, 'a'), 'a');
    });

    test('steps up by z order', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      // z 순서: b(1) → c(3) → a(5)
      expect(nextLayerId(base, 'b'), 'c');
      expect(nextLayerId(base, 'c'), 'a');
    });

    test('top wraps back to bottom', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      expect(nextLayerId(base, 'a'), 'b'); // 맨 위(a) 다음은 맨 아래(b)
    });

    test('full cycle returns to start', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      var id = 'b';
      for (var i = 0; i < 3; i++) {
        id = nextLayerId(base, id)!;
      }
      expect(id, 'b');
    });
  });
}
