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
          colorValue: 0xFF2F6FEB,
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
      expect(a.colorValue, 0xFF2F6FEB);
      // 색이 없는 레이어는 colorValue null(옛 저장본 호환)
      expect(back.layers[1].colorValue, isNull);
    });

    test('empty canvas round-trips', () {
      final back = decodePageCanvas(encodePageCanvas(const PageCanvas()));
      expect(back.isEmpty, isTrue);
    });

    test('layer without color omits the field (byte-compatible with old data)',
        () {
      const layer = DecoLayer(id: 'a', kind: DecoKind.sticker, value: '🌸');
      expect(layer.toJson().containsKey('color'), isFalse);
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

  group('addPhotoLayer', () {
    test('adds a photo layer on top with the given path', () {
      final base = PageCanvas(layers: [_layer('a', z: 2)]);
      final next = addPhotoLayer(base, 'p0', 'data:image/png;base64,AAAA');
      expect(next.layers.length, 2);
      expect(next.layers.last.id, 'p0');
      expect(next.layers.last.kind, DecoKind.photo);
      expect(next.layers.last.value, 'data:image/png;base64,AAAA');
      expect(next.layers.last.z, 3); // topZ+1
      expect(base.layers.length, 1); // input unchanged
    });

    test('empty or blank path returns the canvas unchanged', () {
      final base = PageCanvas(layers: [_layer('a')]);
      expect(addPhotoLayer(base, 'p0', '').layers.length, 1);
      expect(addPhotoLayer(base, 'p0', '   ').layers.length, 1);
    });

    test('clamps the center position into 0..1', () {
      final next = addPhotoLayer(const PageCanvas(), 'p0', 'x', x: 1.7, y: -0.3);
      expect(next.layers.single.x, 1);
      expect(next.layers.single.y, 0);
    });
  });

  group('addTextLayer', () {
    test('adds a trimmed text layer on top', () {
      final base = PageCanvas(layers: [_layer('a', z: 2)]);
      final next = addTextLayer(base, 'x0', '  오늘의 한마디  ');
      expect(next.layers.length, 2);
      expect(next.layers.last.id, 'x0');
      expect(next.layers.last.kind, DecoKind.text);
      expect(next.layers.last.value, '오늘의 한마디'); // trimmed
      expect(next.layers.last.z, 3); // topZ+1
      expect(base.layers.length, 1); // input unchanged
    });

    test('empty or blank text returns the canvas unchanged', () {
      final base = PageCanvas(layers: [_layer('a')]);
      expect(addTextLayer(base, 'x0', '').layers.length, 1);
      expect(addTextLayer(base, 'x0', '   ').layers.length, 1);
    });

    test('clamps the center position into 0..1', () {
      final next = addTextLayer(const PageCanvas(), 'x0', 'hi', x: 1.7, y: -0.3);
      expect(next.layers.single.x, 1);
      expect(next.layers.single.y, 0);
    });

    test('carries the ink color when given, null by default', () {
      final colored =
          addTextLayer(const PageCanvas(), 'x0', 'hi', colorValue: 0xFFE5484D);
      expect(colored.layers.single.colorValue, 0xFFE5484D);
      final plain = addTextLayer(const PageCanvas(), 'x1', 'hi');
      expect(plain.layers.single.colorValue, isNull);
    });
  });

  group('addTapeLayer', () {
    test('adds a tape layer on top with the given style and a tilt', () {
      final base = PageCanvas(layers: [_layer('a', z: 2)]);
      final next = addTapeLayer(base, 't0', 'pink');
      expect(next.layers.length, 2);
      expect(next.layers.last.id, 't0');
      expect(next.layers.last.kind, DecoKind.tape);
      expect(next.layers.last.value, 'pink');
      expect(next.layers.last.z, 3); // topZ+1
      expect(next.layers.last.rotation, -8); // default tilt preserved
      expect(base.layers.length, 1); // input unchanged
    });

    test('empty or blank style returns the canvas unchanged', () {
      final base = PageCanvas(layers: [_layer('a')]);
      expect(addTapeLayer(base, 't0', '').layers.length, 1);
      expect(addTapeLayer(base, 't0', '   ').layers.length, 1);
    });

    test('clamps the center position into 0..1', () {
      final next = addTapeLayer(const PageCanvas(), 't0', 'mint', x: 1.7, y: -0.3);
      expect(next.layers.single.x, 1);
      expect(next.layers.single.y, 0);
    });
  });

  group('pageCanvasSummary', () {
    test('counts stickers and photos, joins non-zero kinds', () {
      final canvas = PageCanvas(layers: [
        _layer('a', kind: DecoKind.sticker),
        _layer('b', kind: DecoKind.sticker),
        DecoLayer(id: 'p', kind: DecoKind.photo, value: 'x'),
      ]);
      expect(pageCanvasSummary(canvas), '스티커 2 · 사진 1');
    });

    test('shows only the present kind', () {
      final canvas = PageCanvas(layers: [
        DecoLayer(id: 'p', kind: DecoKind.photo, value: 'x'),
      ]);
      expect(pageCanvasSummary(canvas), '사진 1');
    });

    test('null when there are no layers (even with paper set)', () {
      expect(pageCanvasSummary(const PageCanvas()), isNull);
      expect(pageCanvasSummary(const PageCanvas(paper: PaperStyle.grid)), isNull);
    });

    test('counts text layers as 글자, ordered sticker·photo·text', () {
      final canvas = PageCanvas(layers: [
        DecoLayer(id: 't', kind: DecoKind.text, value: 'hi'),
        _layer('a', kind: DecoKind.sticker),
      ]);
      expect(pageCanvasSummary(canvas), '스티커 1 · 글자 1');
    });

    test('counts tape layers as 테이프, ordered after 사진', () {
      final canvas = PageCanvas(layers: [
        DecoLayer(id: 't', kind: DecoKind.tape, value: 'pink'),
        DecoLayer(id: 'p', kind: DecoKind.photo, value: 'x'),
        _layer('a', kind: DecoKind.sticker),
      ]);
      expect(pageCanvasSummary(canvas), '스티커 1 · 사진 1 · 테이프 1');
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

  group('sendLayerToBack', () {
    test('lowers z below the current bottom', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      final next = sendLayerToBack(base, 'b');
      expect(next.layers.firstWhere((l) => l.id == 'b').z, -1);
    });

    test('already at the back → unchanged', () {
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      final next = sendLayerToBack(base, 'a');
      expect(identical(next, base), isTrue);
    });

    test('unknown id → unchanged', () {
      final base = PageCanvas(layers: [_layer('a', z: 0)]);
      expect(identical(sendLayerToBack(base, 'zzz'), base), isTrue);
    });
  });

  group('bottomZ', () {
    test('0 when empty, else lowest z', () {
      expect(const PageCanvas().bottomZ, 0);
      expect(
          PageCanvas(layers: [_layer('a', z: 2), _layer('b', z: 5)]).bottomZ, 2);
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
