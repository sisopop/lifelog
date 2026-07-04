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
}
