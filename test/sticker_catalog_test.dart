import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/sticker_catalog.dart';

void main() {
  group('kStickerCatalog', () {
    test('has categories, each non-empty with a label', () {
      expect(kStickerCatalog, isNotEmpty);
      for (final c in kStickerCatalog) {
        expect(c.stickers, isNotEmpty, reason: '${c.id} has no stickers');
        expect(c.label.trim(), isNotEmpty);
      }
    });

    test('category ids are unique', () {
      final ids = kStickerCatalog.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('allStickers', () {
    test('flattens every category in order', () {
      final flat = allStickers();
      expect(flat.first, kStickerCatalog.first.stickers.first);
      final total =
          kStickerCatalog.fold<int>(0, (n, c) => n + c.stickers.length);
      expect(flat.length, total);
    });

    test('no duplicate stickers across the catalog', () {
      final flat = allStickers();
      expect(flat.toSet().length, flat.length,
          reason: 'duplicate sticker found in catalog');
    });
  });
}
