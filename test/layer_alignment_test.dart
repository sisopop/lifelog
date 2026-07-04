import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/page_canvas.dart';
import 'package:lifelog/features/decorate/page_canvas_view.dart';

DecoLayer _layer({double x = 0.5, double y = 0.5}) =>
    DecoLayer(id: 'a', kind: DecoKind.sticker, value: '🌸', x: x, y: y);

void main() {
  group('layerAlignment', () {
    test('center (0.5, 0.5) maps to Alignment.center', () {
      expect(layerAlignment(_layer(x: 0.5, y: 0.5)), Alignment.center);
    });

    test('top-left (0, 0) maps to Alignment.topLeft', () {
      expect(layerAlignment(_layer(x: 0, y: 0)), Alignment.topLeft);
    });

    test('bottom-right (1, 1) maps to Alignment.bottomRight', () {
      expect(layerAlignment(_layer(x: 1, y: 1)), Alignment.bottomRight);
    });

    test('x and y map independently onto the -1..1 range', () {
      expect(layerAlignment(_layer(x: 0.25, y: 0.75)), const Alignment(-0.5, 0.5));
    });
  });

  group('kPageAspectRatio', () {
    test('is a portrait page (taller than wide)', () {
      // 편집기·상세 합성뷰가 공유하는 세로 페이지 비율. <1 이어야 폭보다 높이가
      // 커서, 짧은 본문에서도 꾸밈 레이어가 뭉치지 않을 만큼 세로 여백이 생긴다.
      expect(kPageAspectRatio, lessThan(1.0));
      expect(kPageAspectRatio, greaterThan(0.0));
    });

    test('a page width yields a taller minimum height', () {
      // DecoratedPageView가 쓰는 최소 높이 계산(w / 비율)이 폭보다 커야 한다.
      const w = 320.0;
      expect(w / kPageAspectRatio, greaterThan(w));
    });
  });
}
