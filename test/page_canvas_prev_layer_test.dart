import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 이전 레이어 선택 테스트는 여기 둔다.
DecoLayer _layer(String id, {int z = 0}) =>
    DecoLayer(id: id, kind: DecoKind.sticker, value: '🌸', z: z);

void main() {
  group('previousLayerId', () {
    test('empty canvas → null', () {
      expect(previousLayerId(const PageCanvas(layers: []), 'a'), isNull);
    });

    test('null current → top (z max) layer', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      expect(previousLayerId(base, null), 'a');
    });

    test('unknown current → top (z max) layer', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
      ]);
      expect(previousLayerId(base, 'zzz'), 'a');
    });

    test('single layer → itself', () {
      final base = PageCanvas(layers: [_layer('a', z: 2)]);
      expect(previousLayerId(base, 'a'), 'a');
    });

    test('steps down by z order', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      // z 순서(아래→위): b(1) → c(3) → a(5)
      expect(previousLayerId(base, 'a'), 'c');
      expect(previousLayerId(base, 'c'), 'b');
    });

    test('bottom wraps back to top', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      expect(previousLayerId(base, 'b'), 'a'); // 맨 아래(b) 이전은 맨 위(a)
    });

    test('next then previous returns to start', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      final n = nextLayerId(base, 'b'); // c
      expect(previousLayerId(base, n), 'b');
    });
  });
}
