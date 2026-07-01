import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
void main() {
  group('addTextLayer italic', () {
    test('passes italic through to the new layer', () {
      final canvas = addTextLayer(const PageCanvas(), 'a', 'hi', italic: true);
      expect(canvas.layers.single.italic, isTrue);
    });

    test('defaults to false (upright)', () {
      final canvas = addTextLayer(const PageCanvas(), 'a', 'hi');
      expect(canvas.layers.single.italic, isFalse);
    });
  });

  group('updateTextLayer italic', () {
    test('replaces italic while keeping position/scale/z', () {
      final base = PageCanvas(layers: [
        addTextLayer(const PageCanvas(), 'a', 'hi')
            .layers
            .single
            .copyWith(x: 0.2, y: 0.3, scale: 1.5, z: 4),
      ]);
      final l = updateTextLayer(base, 'a', 'bye', italic: true).layers.single;
      expect(l.italic, isTrue);
      expect(l.value, 'bye');
      expect([l.x, l.y, l.scale, l.z], [0.2, 0.3, 1.5, 4]);
    });

    test('clears italic back to false when omitted', () {
      final base = PageCanvas(
        layers: [addTextLayer(const PageCanvas(), 'a', 'hi', italic: true).layers.single],
      );
      expect(updateTextLayer(base, 'a', 'hi').layers.single.italic, isFalse);
    });
  });

  group('italic serialization', () {
    test('omitted from toJson when false (byte-compatible with old data)', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi').layers.single;
      expect(l.toJson().containsKey('italic'), isFalse);
    });

    test('emitted and round-trips when true', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi', italic: true).layers.single;
      final json = l.toJson();
      expect(json['italic'], true);
      expect(DecoLayer.fromJson(json).italic, isTrue);
    });

    test('bold and italic are independent', () {
      final l = addTextLayer(const PageCanvas(), 'a', 'hi', bold: true).layers.single;
      expect(l.bold, isTrue);
      expect(l.italic, isFalse);
    });

    test('duplicateLayer copies italic', () {
      final base = PageCanvas(
        layers: [addTextLayer(const PageCanvas(), 'a', 'hi', italic: true).layers.single],
      );
      final dup = duplicateLayer(base, 'a', 'a2');
      expect(dup.layers.firstWhere((l) => l.id == 'a2').italic, isTrue);
    });
  });
}
