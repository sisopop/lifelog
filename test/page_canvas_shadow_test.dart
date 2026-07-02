import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
void main() {
  group('addTextLayer shadow', () {
    test('passes shadow through to the new layer', () {
      final canvas = addTextLayer(const PageCanvas(), 'a', 'hi', shadow: true);
      expect(canvas.layers.single.shadow, isTrue);
    });

    test('defaults to false (no shadow)', () {
      final canvas = addTextLayer(const PageCanvas(), 'a', 'hi');
      expect(canvas.layers.single.shadow, isFalse);
    });
  });

  group('updateTextLayer shadow', () {
    test('replaces shadow while keeping position/scale/z', () {
      final base = PageCanvas(layers: [
        addTextLayer(const PageCanvas(), 'a', 'hi')
            .layers
            .single
            .copyWith(x: 0.2, y: 0.3, scale: 1.5, z: 4),
      ]);
      final l = updateTextLayer(base, 'a', 'bye', shadow: true).layers.single;
      expect(l.shadow, isTrue);
      expect(l.value, 'bye');
      expect([l.x, l.y, l.scale, l.z], [0.2, 0.3, 1.5, 4]);
    });

    test('clears shadow back to false when omitted', () {
      final base = PageCanvas(
        layers: [
          addTextLayer(const PageCanvas(), 'a', 'hi', shadow: true)
              .layers
              .single
        ],
      );
      expect(updateTextLayer(base, 'a', 'hi').layers.single.shadow, isFalse);
    });
  });

  group('shadow serialization', () {
    test('omitted from toJson when false (byte-compatible with old data)', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi').layers.single;
      expect(l.toJson().containsKey('shadow'), isFalse);
    });

    test('emitted and round-trips when true', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi', shadow: true)
          .layers
          .single;
      final json = l.toJson();
      expect(json['shadow'], true);
      expect(DecoLayer.fromJson(json).shadow, isTrue);
    });

    test('strike and shadow are independent (can combine)', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi',
              strike: true, shadow: true)
          .layers
          .single;
      expect(l.strike, isTrue);
      expect(l.shadow, isTrue);
    });

    test('duplicateLayer copies shadow', () {
      final base = PageCanvas(
        layers: [
          addTextLayer(const PageCanvas(), 'a', 'hi', shadow: true)
              .layers
              .single
        ],
      );
      final dup = duplicateLayer(base, 'a', 'a2');
      expect(dup.layers.firstWhere((l) => l.id == 'a2').shadow, isTrue);
    });
  });
}
