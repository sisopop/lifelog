import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/content_flow.dart';

void main() {
  group('buildContentFlow', () {
    test('no photos → single text block with the whole content', () {
      final blocks = buildContentFlow('one\n\ntwo', const []);
      expect(blocks.length, 1);
      expect(blocks.single.kind, FlowBlockKind.text);
      expect(blocks.single.text, 'one\n\ntwo');
    });

    test('a photo in the middle splits text top / photo / bottom', () {
      final blocks = buildContentFlow(
        'p1\n\np2\n\np3',
        const [InlinePhoto(path: 'x', afterParagraph: 1)],
      );
      expect(blocks.map((b) => b.kind), [
        FlowBlockKind.text,
        FlowBlockKind.photo,
        FlowBlockKind.text,
      ]);
      expect(blocks[0].text, 'p1');
      expect(blocks[1].photoPath, 'x');
      expect(blocks[2].text, 'p2\n\np3');
    });

    test('two photos → text count is photos + 1', () {
      final blocks = buildContentFlow(
        'a\n\nb\n\nc',
        const [
          InlinePhoto(path: 'x', afterParagraph: 1),
          InlinePhoto(path: 'y', afterParagraph: 2),
        ],
      );
      expect(blocks.map((b) => b.kind), [
        FlowBlockKind.text,
        FlowBlockKind.photo,
        FlowBlockKind.text,
        FlowBlockKind.photo,
        FlowBlockKind.text,
      ]);
      expect(blocks.where((b) => b.kind == FlowBlockKind.text).length, 3);
    });

    test('afterParagraph 0 puts the photo at the very top', () {
      final blocks = buildContentFlow(
        'only',
        const [InlinePhoto(path: 'x', afterParagraph: 0)],
      );
      expect(blocks.map((b) => b.kind),
          [FlowBlockKind.photo, FlowBlockKind.text]);
    });

    test('out-of-range afterParagraph clamps to the end', () {
      final blocks = buildContentFlow(
        'a\n\nb',
        const [InlinePhoto(path: 'x', afterParagraph: 99)],
      );
      expect(blocks.map((b) => b.kind),
          [FlowBlockKind.text, FlowBlockKind.photo]);
      expect(blocks.first.text, 'a\n\nb');
    });

    test('same position keeps photos in insertion order, no text between', () {
      final blocks = buildContentFlow(
        'a\n\nb',
        const [
          InlinePhoto(path: 'x', afterParagraph: 1),
          InlinePhoto(path: 'y', afterParagraph: 1),
        ],
      );
      expect(blocks.map((b) => b.kind), [
        FlowBlockKind.text,
        FlowBlockKind.photo,
        FlowBlockKind.photo,
        FlowBlockKind.text,
      ]);
      expect(blocks[1].photoPath, 'x');
      expect(blocks[2].photoPath, 'y');
    });

    test('blank-path photos are skipped', () {
      final blocks = buildContentFlow(
        'a\n\nb',
        const [InlinePhoto(path: '  ', afterParagraph: 1)],
      );
      expect(blocks.length, 1);
      expect(blocks.single.kind, FlowBlockKind.text);
    });

    test('empty content with no photos → empty list', () {
      expect(buildContentFlow('   ', const []), isEmpty);
    });

    test('empty content but a photo → just the photo block', () {
      final blocks = buildContentFlow(
        '',
        const [InlinePhoto(path: 'x', afterParagraph: 0)],
      );
      expect(blocks.length, 1);
      expect(blocks.single.kind, FlowBlockKind.photo);
    });
  });
}
