import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
void main() {
  group('addTextLayer underline', () {
    test('passes underline through to the new layer', () {
      final canvas =
          addTextLayer(const PageCanvas(), 'a', 'hi', underline: true);
      expect(canvas.layers.single.underline, isTrue);
    });

    test('defaults to false (no underline)', () {
      final canvas = addTextLayer(const PageCanvas(), 'a', 'hi');
      expect(canvas.layers.single.underline, isFalse);
    });
  });

  group('updateTextLayer underline', () {
    test('replaces underline while keeping position/scale/z', () {
      final base = PageCanvas(layers: [
        addTextLayer(const PageCanvas(), 'a', 'hi')
            .layers
            .single
            .copyWith(x: 0.2, y: 0.3, scale: 1.5, z: 4),
      ]);
      final l = updateTextLayer(base, 'a', 'bye', underline: true).layers.single;
      expect(l.underline, isTrue);
      expect(l.value, 'bye');
      expect([l.x, l.y, l.scale, l.z], [0.2, 0.3, 1.5, 4]);
    });

    test('clears underline back to false when omitted', () {
      final base = PageCanvas(
        layers: [
          addTextLayer(const PageCanvas(), 'a', 'hi', underline: true)
              .layers
              .single
        ],
      );
      expect(updateTextLayer(base, 'a', 'hi').layers.single.underline, isFalse);
    });
  });

  group('underline serialization', () {
    test('omitted from toJson when false (byte-compatible with old data)', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi').layers.single;
      expect(l.toJson().containsKey('underline'), isFalse);
    });

    test('emitted and round-trips when true', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi', underline: true)
          .layers
          .single;
      final json = l.toJson();
      expect(json['underline'], true);
      expect(DecoLayer.fromJson(json).underline, isTrue);
    });

    test('bold, italic and underline are independent', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi', bold: true)
          .layers
          .single;
      expect(l.bold, isTrue);
      expect(l.italic, isFalse);
      expect(l.underline, isFalse);
    });

    test('duplicateLayer copies underline', () {
      final base = PageCanvas(
        layers: [
          addTextLayer(const PageCanvas(), 'a', 'hi', underline: true)
              .layers
              .single
        ],
      );
      final dup = duplicateLayer(base, 'a', 'a2');
      expect(dup.layers.firstWhere((l) => l.id == 'a2').underline, isTrue);
    });
  });
}
