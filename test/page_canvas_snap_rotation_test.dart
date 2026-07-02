import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// page_canvas_test.dart가 상한(500줄)을 넘어, 새 순수함수 테스트는 여기에 둔다.
DecoLayer _text(String id) =>
    addTextLayer(const PageCanvas(), id, 'hi').layers.single;

void main() {
  group('snapLayerRotation', () {
    test('rounds up to nearest right angle, keeping other props', () {
      final base = PageCanvas(layers: [
        _text('a')
            .copyWith(rotation: 75, x: 0.3, y: 0.4, scale: 1.5, z: 4),
      ]);
      final l = snapLayerRotation(base, 'a').layers.single;
      expect(l.rotation, closeTo(90, 1e-9));
      expect([l.x, l.y, l.scale, l.z], [0.3, 0.4, 1.5, 4]);
    });

    test('rounds down when closer to the lower right angle', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 30)]);
      expect(snapLayerRotation(base, 'a').layers.single.rotation,
          closeTo(0, 1e-9));
    });

    test('rounds halves up (45 -> 90)', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 45)]);
      expect(snapLayerRotation(base, 'a').layers.single.rotation,
          closeTo(90, 1e-9));
    });

    test('snaps 135 to 180', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 135)]);
      expect(snapLayerRotation(base, 'a').layers.single.rotation,
          closeTo(180, 1e-9));
    });

    test('wraps 315° up to 0°', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 315)]);
      expect(snapLayerRotation(base, 'a').layers.single.rotation,
          closeTo(0, 1e-9));
    });

    test('already on a right angle returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 90)]);
      expect(identical(snapLayerRotation(base, 'a'), base), isTrue);
    });

    test('zero rotation returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 0)]);
      expect(identical(snapLayerRotation(base, 'a'), base), isTrue);
    });

    test('unknown id returns the same instance', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 75)]);
      expect(identical(snapLayerRotation(base, 'zzz'), base), isTrue);
    });

    test('only the target layer moves', () {
      final base = PageCanvas(layers: [
        _text('a').copyWith(rotation: 75),
        _text('b').copyWith(rotation: 30),
      ]);
      final b =
          snapLayerRotation(base, 'a').layers.firstWhere((l) => l.id == 'b');
      expect(b.rotation, 30);
    });

    test('idempotent — snapping twice equals snapping once', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 75)]);
      final once = snapLayerRotation(base, 'a');
      expect(identical(snapLayerRotation(once, 'a'), once), isTrue);
    });

    test('does not mutate the original', () {
      final base = PageCanvas(layers: [_text('a').copyWith(rotation: 75)]);
      snapLayerRotation(base, 'a');
      expect(base.layers.single.rotation, 75);
    });
  });
}
