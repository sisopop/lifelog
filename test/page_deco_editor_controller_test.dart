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

    test('setBoxText mutates the textbox text', () {
      final c = PageDecoEditorController();
      c.addTextBox();
      final id = c.canvas.layers.single.id;
      c.setBoxText(id, '직접 입력한 글');
      expect(c.canvas.layers.single.value, '직접 입력한 글');
      addTearDown(c.dispose);
    });

    test('resizeBox grows a textbox width+height independently (우하 손잡이)', () {
      final c = PageDecoEditorController();
      c.addTextBox();
      final l = c.canvas.layers.single;
      final x0 = l.x, y0 = l.y; // addTextBox는 위치를 살짝 랜덤 배치한다.
      // 우하 손잡이: 오른쪽(+10)·아래(+20)로 끌면 폭 10/100=0.1, 높이 20/100=0.2 각각
      // 커진다(비율 미유지). 좌·상 변 고정을 위해 중심도 dw/2=0.05, dh/2=0.1 이동.
      c.resizeBox(l, 10, 20, 100, 100);
      final after = c.canvas.layers.single;
      expect(after.boxW, closeTo(kDefaultTextBoxW + 0.1, 1e-9));
      expect(after.boxH, closeTo(kDefaultTextBoxH + 0.2, 1e-9));
      expect(after.x, closeTo(x0 + 0.05, 1e-9), reason: 'left edge pinned');
      expect(after.y, closeTo(y0 + 0.1, 1e-9), reason: 'top edge pinned');
      expect(c.selectedId, l.id);
      addTearDown(c.dispose);
    });

    test('resizeBox scales a non-textbox layer proportionally', () {
      final c = PageDecoEditorController();
      c.addSticker('🌸');
      final l = c.canvas.layers.single;
      expect(l.scale, 1.0);
      // 우하 손잡이: 오른쪽(+25)·아래(+25) → (25/100 + 25/100)*2.0 = 1.0 배율 증가.
      c.resizeBox(l, 25, 25, 100, 100);
      expect(c.canvas.layers.single.scale, closeTo(2.0, 1e-9));
      expect(c.selectedId, l.id);
      addTearDown(c.dispose);
    });

    test('rotateLayer rotates a non-textbox layer by drag delta', () {
      final c = PageDecoEditorController();
      c.addSticker('🌸');
      final l = c.canvas.layers.single;
      expect(l.rotation, 0.0);
      // 좌하 회전 손잡이: 왼쪽으로 50px → -(-50+0)*0.6 = 30도 회전.
      c.rotateLayer(l, -50, 0);
      expect(c.canvas.layers.single.rotation, closeTo(30.0, 1e-9));
      addTearDown(c.dispose);
    });
  });
}
