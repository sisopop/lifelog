import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';

// 텍스트박스(사용자가 크기를 정한 빈 상자에 직접 글을 쓰는 요소) 전용 순수 연산
// (page_canvas_textbox.dart)의 단위 테스트. 일반 "글자 넣기"(addTextLayer)와 달리
// ①빈 값도 추가되고 ②boxW·boxH 크기를 조절·저장한다는 점을 검증한다.
void main() {
  group('addTextBoxLayer', () {
    test('adds an empty box (unlike addTextLayer which rejects blank)', () {
      final c = addTextBoxLayer(const PageCanvas(), 'b0');
      expect(c.layers, hasLength(1));
      final l = c.layers.first;
      expect(l.kind, DecoKind.textbox);
      expect(l.value, '');
      expect(l.boxW, kDefaultTextBoxW);
      expect(l.boxH, kDefaultTextBoxH);
    });

    test('clamps requested size into the allowed range', () {
      final c = addTextBoxLayer(const PageCanvas(), 'b0', boxW: 5.0, boxH: 0.0);
      final l = c.layers.first;
      expect(l.boxW, kMaxTextBoxSize);
      expect(l.boxH, kMinTextBoxSize);
    });

    test('keeps supplied initial text and position', () {
      final c =
          addTextBoxLayer(const PageCanvas(), 'b0', text: '메모', x: 0.2, y: 0.7);
      final l = c.layers.first;
      expect(l.value, '메모');
      expect(l.x, 0.2);
      expect(l.y, 0.7);
    });

    test('stacks on top (z = topZ + 1)', () {
      final base = PageCanvas(layers: [
        const DecoLayer(id: 's', kind: DecoKind.sticker, value: '🌸', z: 3),
      ]);
      final c = addTextBoxLayer(base, 'b0');
      expect(c.layers.last.z, 4);
    });
  });

  group('resizeTextBoxWidth', () {
    test('updates+clamps width and shifts x to keep the left edge fixed', () {
      // 기본 폭 0.5, 중심 x 0.5. 폭을 1.0(최대)으로 키우면 dw=0.5, 왼쪽 변을 고정하려면
      // 중심 x가 dw/2=0.25 오른쪽으로 옮겨 0.75가 된다(높이·y는 그대로).
      final c = addTextBoxLayer(const PageCanvas(), 'b0');
      final r = resizeTextBoxWidth(c, 'b0', 5.0);
      final l = r.layers.first;
      expect(l.boxW, kMaxTextBoxSize);
      expect(l.boxH, kDefaultTextBoxH, reason: 'height untouched');
      expect(l.x, closeTo(0.75, 1e-9), reason: 'center shifts to pin left edge');
      expect(l.y, 0.5, reason: 'y untouched');
    });

    test('ignores non-textbox layers', () {
      final base = PageCanvas(layers: [
        const DecoLayer(id: 't', kind: DecoKind.text, value: 'hi'),
      ]);
      expect(identical(resizeTextBoxWidth(base, 't', 0.5), base), isTrue);
    });

    test('returns same instance when width unchanged', () {
      final c = addTextBoxLayer(const PageCanvas(), 'b0', boxW: 0.5, boxH: 0.3);
      expect(identical(resizeTextBoxWidth(c, 'b0', 0.5), c), isTrue);
    });
  });

  group('resizeTextBoxHeight', () {
    test('updates+clamps height and shifts y to keep the top edge fixed', () {
      // 기본 높이 0.18, 중심 y 0.5. 높이를 1.0(최대)으로 키우면 dh=0.82, 위쪽 변을
      // 고정하려면 중심 y가 dh/2=0.41 아래로 옮겨 0.91이 된다(폭·x는 그대로).
      final c = addTextBoxLayer(const PageCanvas(), 'b0');
      final r = resizeTextBoxHeight(c, 'b0', 5.0);
      final l = r.layers.first;
      expect(l.boxH, kMaxTextBoxSize);
      expect(l.boxW, kDefaultTextBoxW, reason: 'width untouched');
      expect(l.y, closeTo(0.91, 1e-9), reason: 'center shifts to pin top edge');
      expect(l.x, 0.5, reason: 'x untouched');
    });

    test('ignores non-textbox layers', () {
      final base = PageCanvas(layers: [
        const DecoLayer(id: 't', kind: DecoKind.text, value: 'hi'),
      ]);
      expect(identical(resizeTextBoxHeight(base, 't', 0.5), base), isTrue);
    });

    test('returns same instance when height unchanged', () {
      final c = addTextBoxLayer(const PageCanvas(), 'b0', boxW: 0.5, boxH: 0.3);
      expect(identical(resizeTextBoxHeight(c, 'b0', 0.3), c), isTrue);
    });
  });

  group('setTextBoxText', () {
    test('sets the text (empty allowed)', () {
      final c = addTextBoxLayer(const PageCanvas(), 'b0', text: '처음');
      final r = setTextBoxText(c, 'b0', '바뀐 글');
      expect(r.layers.first.value, '바뀐 글');
      final cleared = setTextBoxText(r, 'b0', '');
      expect(cleared.layers.first.value, '');
    });

    test('ignores non-textbox layers', () {
      final base = PageCanvas(layers: [
        const DecoLayer(id: 't', kind: DecoKind.text, value: 'hi'),
      ]);
      expect(identical(setTextBoxText(base, 't', 'x'), base), isTrue);
    });

    test('returns same instance when text unchanged', () {
      final c = addTextBoxLayer(const PageCanvas(), 'b0', text: '같음');
      expect(identical(setTextBoxText(c, 'b0', '같음'), c), isTrue);
    });
  });

  group('textbox serialization round-trip', () {
    test('boxW/boxH survive encode → decode', () {
      final c = addTextBoxLayer(const PageCanvas(), 'b0',
          text: '저장', boxW: 0.6, boxH: 0.25);
      final restored = decodePageCanvas(encodePageCanvas(c));
      final l = restored.layers.single;
      expect(l.kind, DecoKind.textbox);
      expect(l.value, '저장');
      expect(l.boxW, 0.6);
      expect(l.boxH, 0.25);
    });

    test('a layer without box size keeps null (byte-compatible)', () {
      const c = PageCanvas(layers: [
        DecoLayer(id: 's', kind: DecoKind.sticker, value: '🌸'),
      ]);
      final restored = decodePageCanvas(encodePageCanvas(c));
      expect(restored.layers.single.boxW, isNull);
      expect(restored.layers.single.boxH, isNull);
    });
  });

  group('pageCanvasSummary counts textboxes', () {
    test('appends 텍스트박스 count', () {
      final c = addTextBoxLayer(const PageCanvas(), 'b0');
      expect(pageCanvasSummary(c), '텍스트박스 1');
    });
  });
}
