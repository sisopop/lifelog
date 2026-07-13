import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';
import 'package:lifelog/features/decorate/page_deco_editor.dart';

/// Phase 2(글쓰기 탭 통합)에서 PageDecoEditorController가 캔버스의 단일 소유자가
/// 됐으므로, 저장/프리필이 기대는 isBlank·load·hasLayers 규칙을 지킨다.
void main() {
  group('PageDecoEditorController', () {
    test('a fresh controller is blank (nothing to persist)', () {
      final c = PageDecoEditorController();
      expect(c.isBlank, isTrue);
      expect(c.hasLayers, isFalse);
      addTearDown(c.dispose);
    });

    test('initial canvas with a layer is not blank', () {
      final c = PageDecoEditorController(
        initial: const PageCanvas(
          layers: [DecoLayer(id: 'a', kind: DecoKind.sticker, value: '🌸')],
        ),
      );
      expect(c.isBlank, isFalse);
      expect(c.hasLayers, isTrue);
      addTearDown(c.dispose);
    });

    test('changing only paper/color counts as decorated (not blank)', () {
      final c = PageDecoEditorController();
      c.setPaperStyle(PaperStyle.grid);
      expect(c.isBlank, isFalse);
      c.setPaperStyle(PaperStyle.plain);
      expect(c.isBlank, isTrue, reason: 'back to plain + no color is blank');
      c.setPaperColorValue(0xFFFFF1A8);
      expect(c.isBlank, isFalse);
      addTearDown(c.dispose);
    });

    test('load replaces the whole canvas and clears selection', () {
      final c = PageDecoEditorController();
      c.addSticker('🌸');
      expect(c.hasLayers, isTrue);
      expect(c.selectedId, isNotNull);

      c.load(const PageCanvas());
      expect(c.hasLayers, isFalse);
      expect(c.isBlank, isTrue);
      expect(c.selectedId, isNull);

      c.load(const PageCanvas(
        layers: [DecoLayer(id: 'x', kind: DecoKind.tape, value: 'mint')],
      ));
      expect(c.hasLayers, isTrue);
      expect(c.selectedId, isNull, reason: 'load never keeps a selection');
      addTearDown(c.dispose);
    });

    test('undoLast/clearLayers keep the chosen paper', () {
      final c = PageDecoEditorController();
      c.setPaperStyle(PaperStyle.dotted);
      c.addSticker('🌸');
      c.addSticker('🌼');
      c.undoLast();
      expect(c.canvas.layers.length, 1);
      c.clearLayers();
      expect(c.hasLayers, isFalse);
      expect(c.canvas.paper, PaperStyle.dotted,
          reason: 'clear keeps paper style');
      addTearDown(c.dispose);
    });

    test('addTextBox adds an empty selected textbox with default size', () {
      final c = PageDecoEditorController();
      c.addTextBox();
      final l = c.canvas.layers.single;
      expect(l.kind, DecoKind.textbox);
      expect(l.value, '');
      expect(l.boxW, kDefaultTextBoxW);
      expect(c.selectedId, l.id);
      addTearDown(c.dispose);
    });

    test('setBoxText and resizeBox mutate the textbox', () {
      final c = PageDecoEditorController();
      c.addTextBox();
      final id = c.canvas.layers.single.id;
      c.setBoxText(id, '직접 입력한 글');
      expect(c.canvas.layers.single.value, '직접 입력한 글');
      // 100px 페이지에서 오른쪽·아래로 10px 끌면 2*10/100 = 0.2씩 커진다.
      final before = c.canvas.layers.single;
      c.resizeBox(before, 10, 10, 100, 100);
      final after = c.canvas.layers.single;
      expect(after.boxW, closeTo(kDefaultTextBoxW + 0.2, 1e-9));
      expect(after.boxH, closeTo(kDefaultTextBoxH + 0.2, 1e-9));
      addTearDown(c.dispose);
    });

    test('resizeLayer scales a non-textbox layer by drag delta', () {
      final c = PageDecoEditorController();
      c.addSticker('🌸');
      final l = c.canvas.layers.single;
      expect(l.scale, 1.0);
      // 100px 페이지에서 우하로 50px → (50/100 + 0/100)*2.0 = 1.0 만큼 배율 증가.
      c.resizeLayer(l, 50, 0, 100, 100);
      expect(c.canvas.layers.single.scale, closeTo(2.0, 1e-9));
      expect(c.selectedId, l.id);
      addTearDown(c.dispose);
    });

    test('rotateLayer rotates a non-textbox layer by drag delta', () {
      final c = PageDecoEditorController();
      c.addSticker('🌸');
      final l = c.canvas.layers.single;
      expect(l.rotation, 0.0);
      // 50px 오른쪽으로 끌면 50*0.6 = 30도 회전.
      c.rotateLayer(l, 50, 0);
      expect(c.canvas.layers.single.rotation, closeTo(30.0, 1e-9));
      addTearDown(c.dispose);
    });

    test('resizeLayer on a textbox delegates to box resize', () {
      final c = PageDecoEditorController();
      c.addTextBox();
      final l = c.canvas.layers.single;
      c.resizeLayer(l, 10, 10, 100, 100);
      final after = c.canvas.layers.single;
      expect(after.boxW, closeTo(kDefaultTextBoxW + 0.2, 1e-9));
      expect(after.boxH, closeTo(kDefaultTextBoxH + 0.2, 1e-9));
      expect(after.scale, 1.0, reason: 'textbox uses box size, not scale');
      addTearDown(c.dispose);
    });
  });
}
