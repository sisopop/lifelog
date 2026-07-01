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
          bold: true,
          bgColorValue: 0xFFFFF1A8,
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
      expect(a.bold, isTrue);
      expect(a.bgColorValue, 0xFFFFF1A8);
      // 색이 없는 레이어는 colorValue null·bold false·bgColorValue null(옛 저장본 호환)
      expect(back.layers[1].colorValue, isNull);
      expect(back.layers[1].bold, isFalse);
      expect(back.layers[1].bgColorValue, isNull);
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

    test('non-bold layer omits the bold field (byte-compatible with old data)',
        () {
      const layer = DecoLayer(id: 'a', kind: DecoKind.text, value: 'hi');
      expect(layer.toJson().containsKey('bold'), isFalse);
      const boldLayer =
          DecoLayer(id: 'b', kind: DecoKind.text, value: 'hi', bold: true);
      expect(boldLayer.toJson()['bold'], true);
    });

    test('layer without highlight omits the bg field (byte-compatible)', () {
      const layer = DecoLayer(id: 'a', kind: DecoKind.text, value: 'hi');
      expect(layer.toJson().containsKey('bg'), isFalse);
      const hl = DecoLayer(
          id: 'b', kind: DecoKind.text, value: 'hi', bgColorValue: 0xFFFFF1A8);
      expect(hl.toJson()['bg'], 0xFFFFF1A8);
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

    test('carries the bold flag when given, false by default', () {
      final bold = addTextLayer(const PageCanvas(), 'x0', 'hi', bold: true);
      expect(bold.layers.single.bold, isTrue);
      final plain = addTextLayer(const PageCanvas(), 'x1', 'hi');
      expect(plain.layers.single.bold, isFalse);
    });

    test('carries the highlight bg when given, null by default', () {
      final hl = addTextLayer(const PageCanvas(), 'x0', 'hi',
          bgColorValue: 0xFFFFF1A8);
      expect(hl.layers.single.bgColorValue, 0xFFFFF1A8);
      final plain = addTextLayer(const PageCanvas(), 'x1', 'hi');
      expect(plain.layers.single.bgColorValue, isNull);
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

  group('removeLastLayer', () {
    test('removes the most recently added layer, keeps earlier ones', () {
      final base =
          PageCanvas(layers: [_layer('a'), _layer('b'), _layer('c')]);
      final next = removeLastLayer(base);
      expect(next.layers.map((l) => l.id), ['a', 'b']);
    });

    test('uses add order, not z — front/back sends do not change target', () {
      // 'a'를 맨 앞으로 올려 z가 가장 높아도, 지워지는 건 마지막에 추가한 'b'.
      final base = PageCanvas(layers: [_layer('a', z: 0), _layer('b', z: 1)]);
      final raised = bringLayerToFront(base, 'a');
      final next = removeLastLayer(raised);
      expect(next.layers.map((l) => l.id), ['a']);
    });

    test('empty canvas → unchanged (same instance)', () {
      const base = PageCanvas();
      expect(identical(removeLastLayer(base), base), isTrue);
    });

    test('does not mutate original, preserves paper + color', () {
      final base = PageCanvas(
        layers: [_layer('a'), _layer('b')],
        paper: PaperStyle.grid,
        paperColorValue: 0xFFEEF4FB,
      );
      final next = removeLastLayer(base);
      expect(base.layers.length, 2); // 원본 불변
      expect(next.paper, PaperStyle.grid);
      expect(next.paperColorValue, 0xFFEEF4FB);
    });
  });

  group('duplicateLayer', () {
    test('copies the layer with a new id, offset and on top', () {
      const src = DecoLayer(
        id: 'a',
        kind: DecoKind.text,
        value: '오늘',
        x: 0.3,
        y: 0.3,
        scale: 1.5,
        rotation: 20,
        z: 4,
        colorValue: 0xFFE5484D,
        bold: true,
        bgColorValue: 0xFFFFF1A8,
      );
      final base = PageCanvas(layers: [src]);
      final next = duplicateLayer(base, 'a', 'a2');
      expect(next.layers.length, 2);
      final copy = next.layers.last;
      expect(copy.id, 'a2');
      expect(copy.kind, DecoKind.text);
      expect(copy.value, '오늘');
      expect(copy.scale, 1.5);
      expect(copy.rotation, 20);
      expect(copy.colorValue, 0xFFE5484D);
      expect(copy.bold, isTrue);
      expect(copy.bgColorValue, 0xFFFFF1A8);
      expect(copy.x, closeTo(0.34, 1e-9)); // 0.3 + dx
      expect(copy.y, closeTo(0.34, 1e-9));
      expect(copy.z, 5); // topZ+1
      expect(base.layers.length, 1); // input unchanged
    });

    test('clamps the offset position into 0..1', () {
      final base = PageCanvas(layers: [_layer('a').copyWith(x: 0.99, y: 0.99)]);
      final copy = duplicateLayer(base, 'a', 'a2').layers.last;
      expect(copy.x, 1);
      expect(copy.y, 1);
    });

    test('unknown id → unchanged', () {
      final base = PageCanvas(layers: [_layer('a')]);
      expect(identical(duplicateLayer(base, 'zzz', 'a2'), base), isTrue);
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

  group('updateTextLayer (글자 편집)', () {
    PageCanvas canvasWithText() => addTextLayer(
          const PageCanvas(),
          't',
          '오타',
          colorValue: 0xFF3A3A3A,
          bold: false,
          bgColorValue: 0xFFFFF1A8,
        );

    test('replaces text/color/bold, keeps position/scale/rotation/z', () {
      final base = replaceLayer(
        canvasWithText(),
        addTextLayer(const PageCanvas(), 't', '오타').layers.single.copyWith(
              x: 0.2,
              y: 0.7,
              scale: 1.8,
              rotation: 30,
              z: 5,
            ),
      );
      final next = updateTextLayer(base, 't', '고침',
          colorValue: 0xFF2F6FEB, bold: true, bgColorValue: null);
      final l = next.layers.single;
      expect(l.value, '고침');
      expect(l.colorValue, 0xFF2F6FEB);
      expect(l.bold, isTrue);
      expect(l.bgColorValue, isNull); // 형광펜 제거(copyWith로는 불가)
      expect(l.x, 0.2);
      expect(l.y, 0.7);
      expect(l.scale, 1.8);
      expect(l.rotation, 30);
      expect(l.z, 5);
    });

    test('trims text and ignores blank edits', () {
      final base = canvasWithText();
      expect(updateTextLayer(base, 't', '  다듬 ').layers.single.value, '다듬');
      // 공백뿐이면 원본 그대로
      expect(updateTextLayer(base, 't', '   ').layers.single.value, '오타');
    });

    test('unknown id or non-text layer is unchanged', () {
      final base = canvasWithText();
      expect(updateTextLayer(base, 'zzz', 'x').layers.single.value, '오타');
      final sticker = PageCanvas(layers: [_layer('s')]);
      expect(updateTextLayer(sticker, 's', 'x').layers.single.value, '🌸');
    });

    test('does not mutate the original canvas', () {
      final base = canvasWithText();
      updateTextLayer(base, 't', '고침', colorValue: 0xFF000000);
      expect(base.layers.single.value, '오타');
    });
  });

  group('paper color (속지 바탕색)', () {
    test('defaults to null (기본 크림)', () {
      expect(const PageCanvas().paperColorValue, isNull);
    });

    test('setPaperColor swaps only the color, keeps paper+layers, no mutation',
        () {
      final base = PageCanvas(paper: PaperStyle.grid, layers: [_layer('a')]);
      final next = setPaperColor(base, 0xFFFFF0F3);
      expect(next.paperColorValue, 0xFFFFF0F3);
      expect(next.paper, PaperStyle.grid);
      expect(next.layers.single.id, 'a');
      expect(base.paperColorValue, isNull); // unchanged
    });

    test('setPaperColor(null) clears back to default cream', () {
      final base = setPaperColor(const PageCanvas(), 0xFFFFF0F3);
      expect(setPaperColor(base, null).paperColorValue, isNull);
    });

    test('round-trips through encode/decode', () {
      final canvas = setPaperColor(const PageCanvas(), 0xFFEFF7F0);
      final back = decodePageCanvas(encodePageCanvas(canvas));
      expect(back.paperColorValue, 0xFFEFF7F0);
    });

    test('toJson omits paperColor when default (byte-compat with old saves)',
        () {
      expect(const PageCanvas().toJson().containsKey('paperColor'), isFalse);
      expect(
          setPaperColor(const PageCanvas(), 0xFF123456)
              .toJson()['paperColor'],
          0xFF123456);
    });

    test('layer ops + setPaper preserve the chosen paper color', () {
      final base = setPaperColor(
          PageCanvas(paper: PaperStyle.lined, layers: [_layer('a')]),
          0xFFF3E9D8);
      expect(addLayer(base, _layer('b')).paperColorValue, 0xFFF3E9D8);
      expect(removeLayer(base, 'a').paperColorValue, 0xFFF3E9D8);
      expect(replaceLayer(base, _layer('a').copyWith(x: 0.1)).paperColorValue,
          0xFFF3E9D8);
      expect(setPaper(base, PaperStyle.dotted).paperColorValue, 0xFFF3E9D8);
    });
  });
}
