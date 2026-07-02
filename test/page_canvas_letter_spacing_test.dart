import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _text(String id) =>
    addTextLayer(const PageCanvas(), id, 'hi').layers.single;

void main() {
  group('stepLayerLetterSpacing', () {
    test('widens spacing by delta, keeping other props', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(x: 0.2, y: 0.3, scale: 1.5, z: 4),
      ]);
      final l = stepLayerLetterSpacing(base, 'a', 1).layers.single;
      expect(l.letterSpacing, 1);
      expect([l.x, l.y, l.scale, l.z], [0.2, 0.3, 1.5, 4]);
    });

    test('narrows spacing by negative delta', () {
      final base = PageCanvas(layers: [_text('a')]);
      final l = stepLayerLetterSpacing(base, 'a', -2).layers.single;
      expect(l.letterSpacing, -2);
    });

    test('clamps to the max', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(letterSpacing: kMaxLetterSpacing),
      ]);
      expect(identical(stepLayerLetterSpacing(base, 'a', 5), base), isTrue);
    });

    test('clamps to the min', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(letterSpacing: kMinLetterSpacing),
      ]);
      expect(identical(stepLayerLetterSpacing(base, 'a', -5), base), isTrue);
    });

    test('unknown id returns the same instance', () {
      final base = PageCanvas(layers: [_text('a')]);
      expect(identical(stepLayerLetterSpacing(base, 'zzz', 1), base), isTrue);
    });

    test('does not mutate the original', () {
      final base = PageCanvas(layers: [_text('a')]);
      stepLayerLetterSpacing(base, 'a', 1);
      expect(base.layers.single.letterSpacing, 0.0);
    });
  });

  group('letterSpacing serialization', () {
    test('defaults to 0.0 and is omitted from toJson', () {
      final l = _text('a');
      expect(l.letterSpacing, 0.0);
      expect(l.toJson().containsKey('ls'), isFalse);
    });

    test('emitted and round-trips when non-zero', () {
      final l = _text('a').copyWith(letterSpacing: 2.5);
      final json = l.toJson();
      expect(json['ls'], 2.5);
      expect(DecoLayer.fromJson(json).letterSpacing, 2.5);
    });

    test('duplicateLayer copies letterSpacing', () {
      final base = PageCanvas(layers: [_text('a').copyWith(letterSpacing: 3)]);
      final dup = duplicateLayer(base, 'a', 'a2');
      expect(dup.layers.firstWhere((l) => l.id == 'a2').letterSpacing, 3);
    });
  });
}
