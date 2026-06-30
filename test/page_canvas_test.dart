import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

DecoLayer _layer(String id, {DecoKind kind = DecoKind.sticker, int z = 0}) =>
    DecoLayer(id: id, kind: kind, value: '🌸', z: z);

void main() {
  group('clampUnit', () {
    test('clamps into 0..1', () {
      expect(clampUnit(-0.3), 0);
      expect(clampUnit(1.4), 1);
      expect(clampUnit(0.42), 0.42);
    });
  });

  group('encode/decode round-trip', () {
    test('preserves every field', () {
      final canvas = PageCanvas(layers: [
        const DecoLayer(
          id: 'a',
          kind: DecoKind.text,
          value: '오늘 하루',
          x: 0.2,
          y: 0.8,
          scale: 1.5,
          rotation: 30,
          z: 3,
        ),
        const DecoLayer(id: 'b', kind: DecoKind.sticker, value: '🌸'),
      ]);
      final back = decodePageCanvas(encodePageCanvas(canvas));
      expect(back.layers.length, 2);
      final a = back.layers.first;
      expect(a.id, 'a');
      expect(a.kind, DecoKind.text);
      expect(a.value, '오늘 하루');
      expect(a.x, 0.2);
      expect(a.y, 0.8);
      expect(a.scale, 1.5);
      expect(a.rotation, 30);
      expect(a.z, 3);
    });

    test('empty canvas round-trips', () {
      final back = decodePageCanvas(encodePageCanvas(const PageCanvas()));
      expect(back.isEmpty, isTrue);
    });
  });

  group('decodePageCanvas tolerance', () {
    test('null / blank / garbage → empty canvas (never throws)', () {
      expect(decodePageCanvas(null).isEmpty, isTrue);
      expect(decodePageCanvas('   ').isEmpty, isTrue);
      expect(decodePageCanvas('not json {{{').isEmpty, isTrue);
      expect(decodePageCanvas('[1,2,3]').isEmpty, isTrue);
    });

    test('unknown kind falls back to sticker', () {
      final c = decodePageCanvas('{"layers":[{"id":"x","kind":"weird"}]}');
      expect(c.layers.single.kind, DecoKind.sticker);
    });

    test('missing coords default to centre and clamp', () {
      final c = decodePageCanvas('{"layers":[{"id":"x","x":2.0,"y":-1.0}]}');
      expect(c.layers.single.x, 1.0);
      expect(c.layers.single.y, 0.0);
    });
  });

  group('topZ', () {
    test('-1 when empty, else highest z', () {
      expect(const PageCanvas().topZ, -1);
      expect(PageCanvas(layers: [_layer('a', z: 2), _layer('b', z: 5)]).topZ, 5);
    });
  });

  group('addLayer', () {
    test('appends on top (topZ+1) and does not mutate input', () {
      final base = PageCanvas(layers: [_layer('a', z: 4)]);
      final next = addLayer(base, _layer('b'));
      expect(next.layers.length, 2);
      expect(next.layers.last.id, 'b');
      expect(next.layers.last.z, 5);
      expect(base.layers.length, 1); // unchanged
    });

    test('first layer gets z 0', () {
      final next = addLayer(const PageCanvas(), _layer('a'));
      expect(next.layers.single.z, 0);
    });
  });

  group('removeLayer', () {
    test('drops the matching id, keeps others', () {
      final base = PageCanvas(layers: [_layer('a'), _layer('b')]);
      final next = removeLayer(base, 'a');
      expect(next.layers.map((l) => l.id), ['b']);
      expect(base.layers.length, 2); // unchanged
    });
  });

  group('replaceLayer', () {
    test('swaps the layer with the same id', () {
      final base = PageCanvas(layers: [_layer('a'), _layer('b')]);
      final moved = _layer('a').copyWith(x: 0.1, y: 0.1);
      final next = replaceLayer(base, moved);
      expect(next.layers.first.x, 0.1);
      expect(next.layers.length, 2);
    });

    test('no match leaves the canvas unchanged', () {
      final base = PageCanvas(layers: [_layer('a')]);
      final next = replaceLayer(base, _layer('zzz'));
      expect(next.layers.map((l) => l.id), ['a']);
    });
  });

  group('bringLayerToFront', () {
    test('raises z above the current top', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      final next = bringLayerToFront(base, 'a');
      expect(next.layers.firstWhere((l) => l.id == 'a').z, 2);
    });

    test('already on top → unchanged', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      final next = bringLayerToFront(base, 'b');
      expect(identical(next, base), isTrue);
    });
  });

  group('layersByZ', () {
    test('sorts ascending for paint order', () {
      final base = PageCanvas(layers: [
        _layer('a', z: 5),
        _layer('b', z: 1),
        _layer('c', z: 3),
      ]);
      expect(layersByZ(base).map((l) => l.id), ['b', 'c', 'a']);
    });
  });

  group('paper (속지 무늬)', () {
    test('defaults to plain', () {
      expect(const PageCanvas().paper, PaperStyle.plain);
    });

    test('round-trips through encode/decode', () {
      final canvas = PageCanvas(paper: PaperStyle.grid, layers: [_layer('a')]);
      final back = decodePageCanvas(encodePageCanvas(canvas));
      expect(back.paper, PaperStyle.grid);
      expect(back.layers.single.id, 'a');
    });

    test('unknown / missing paper name falls back to plain', () {
      expect(decodePageCanvas('{"paper":"weird"}').paper, PaperStyle.plain);
      expect(decodePageCanvas('{"layers":[]}').paper, PaperStyle.plain);
    });

    test('setPaper swaps only the style, keeps layers, no mutation', () {
      final base = PageCanvas(layers: [_layer('a'), _layer('b')]);
      final next = setPaper(base, PaperStyle.dotted);
      expect(next.paper, PaperStyle.dotted);
      expect(next.layers.map((l) => l.id), ['a', 'b']);
      expect(base.paper, PaperStyle.plain); // unchanged
    });

    test('layer ops preserve the chosen paper', () {
      final base = PageCanvas(paper: PaperStyle.lined, layers: [_layer('a')]);
      expect(addLayer(base, _layer('b')).paper, PaperStyle.lined);
      expect(removeLayer(base, 'a').paper, PaperStyle.lined);
      expect(replaceLayer(base, _layer('a').copyWith(x: 0.1)).paper,
          PaperStyle.lined);
    });
  });
}
