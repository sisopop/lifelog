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
  });
}
