import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _text(String id) =>
    addTextLayer(const PageCanvas(), id, 'hi').layers.single;

void main() {
  group('resetLayerLetterSpacing', () {
    test('resets to 0.0 while keeping other props', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(letterSpacing: 4, x: 0.2, y: 0.3, scale: 1.5, z: 4),
      ]);
      final l = resetLayerLetterSpacing(base, 'a').layers.single;
      expect(l.letterSpacing, 0.0);
      expect([l.x, l.y, l.scale, l.z], [0.2, 0.3, 1.5, 4]);
    });

    test('already 0.0 returns the same instance', () {
      final base = PageCanvas(layers: [_text('a')]);
      expect(identical(resetLayerLetterSpacing(base, 'a'), base), isTrue);
    });

    test('unknown id returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(letterSpacing: 4)]);
      expect(identical(resetLayerLetterSpacing(base, 'zzz'), base), isTrue);
    });

    test('only the target layer is reset', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(letterSpacing: 4),
        _text('b').copyWith(letterSpacing: 2),
      ]);
      final out = resetLayerLetterSpacing(base, 'a');
      expect(out.layers.firstWhere((l) => l.id == 'a').letterSpacing, 0.0);
      expect(out.layers.firstWhere((l) => l.id == 'b').letterSpacing, 2);
    });

    test('does not mutate the original', () {
      final base = PageCanvas(layers: [_text('a').copyWith(letterSpacing: 4)]);
      resetLayerLetterSpacing(base, 'a');
      expect(base.layers.single.letterSpacing, 4);
    });
  });
}
