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

  group('splitContentParagraphs', () {
    test('splits on blank lines, trims, drops empties', () {
      expect(splitContentParagraphs('a\n\nb'), ['a', 'b']);
      expect(splitContentParagraphs('  a  \n\n\n  b '), ['a', 'b']);
      expect(splitContentParagraphs('single line'), ['single line']);
      expect(splitContentParagraphs('   '), isEmpty);
    });
  });

  group('encode/decode inline photos', () {
    test('round-trips path and afterParagraph', () {
      final photos = [
        const InlinePhoto(path: 'data:image/png;base64,AAAA', afterParagraph: 2),
        const InlinePhoto(path: 'http://x/y.jpg', afterParagraph: 0),
      ];
      final back = decodeInlinePhotos(encodeInlinePhotos(photos));
      expect(back.length, 2);
      expect(back[0].path, 'data:image/png;base64,AAAA');
      expect(back[0].afterParagraph, 2);
      expect(back[1].path, 'http://x/y.jpg');
      expect(back[1].afterParagraph, 0);
    });

    test('empty list round-trips', () {
      expect(decodeInlinePhotos(encodeInlinePhotos(const [])), isEmpty);
    });

    test('null / blank / garbage → empty list (never throws)', () {
      expect(decodeInlinePhotos(null), isEmpty);
      expect(decodeInlinePhotos('   '), isEmpty);
      expect(decodeInlinePhotos('not json {{{'), isEmpty);
      expect(decodeInlinePhotos('{"not":"a list"}'), isEmpty);
    });

    test('missing fields default (path empty, afterParagraph 0)', () {
      final back = decodeInlinePhotos('[{"path":"x"},{"afterParagraph":3}]');
      expect(back.length, 2);
      expect(back[0].afterParagraph, 0);
      expect(back[1].path, '');
      expect(back[1].afterParagraph, 3);
    });
  });
}
