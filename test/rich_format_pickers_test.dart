import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/features/decorate/rich_format_pickers.dart';

void main() {
  group('richSizeOptionIndex', () {
    test('null token maps to 기본(index 0)', () {
      expect(richSizeOptionIndex(null), 0);
      expect(kRichSizeOptions.first.token, isNull);
      expect(kRichSizeOptions.first.label, '기본');
    });

    test('known tokens map to their option', () {
      expect(kRichSizeOptions[richSizeOptionIndex('small')].token, 'small');
      expect(kRichSizeOptions[richSizeOptionIndex('large')].token, 'large');
      expect(kRichSizeOptions[richSizeOptionIndex('huge')].token, 'huge');
    });

    test('unknown token falls back to 기본(index 0)', () {
      expect(richSizeOptionIndex('gigantic'), 0);
    });
  });

  group('color charts', () {
    test('ink chart is a full 8-wide grid', () {
      expect(kRichInkChart.length, 32);
      expect(kRichInkChart.length % 8, 0);
    });

    test('highlight chart has 8 pastel swatches', () {
      expect(kRichHighlightChart.length, 8);
    });

    test('charts hold no duplicate colors', () {
      expect(kRichInkChart.toSet().length, kRichInkChart.length);
      expect(kRichHighlightChart.toSet().length, kRichHighlightChart.length);
    });
  });
}
