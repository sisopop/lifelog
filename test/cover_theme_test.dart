import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/decorate/cover_theme.dart';
import 'package:lifelog/shared/models/enums.dart';
import 'package:lifelog/shared/models/journal.dart';

Journal _journal() => Journal(
      journalId: 'j1',
      ownerId: 'u1',
      type: JournalType.personal,
      title: '나의 일기장',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('applyCoverTheme', () {
    test('applies every layer field from the theme', () {
      const theme = CoverTheme(
        id: 't',
        label: '테스트',
        icon: '🎀',
        color: 0xFFEF6F9E,
        texture: 'fabric',
        binding: 'spiral',
        corner: 'tape',
        band: 'buckle',
        ribbon: 'pink',
        clip: 'pink',
        tab: 'pink',
      );
      final j = applyCoverTheme(_journal(), theme);
      expect(j.coverColor, 0xFFEF6F9E);
      expect(j.icon, '🎀');
      expect(j.coverTexture, 'fabric');
      expect(j.coverBinding, 'spiral');
      expect(j.coverCorner, 'tape');
      expect(j.coverBand, 'buckle');
      expect(j.coverRibbon, 'pink');
      expect(j.coverClip, 'pink');
      expect(j.coverTab, 'pink');
      expect(j.coverPattern, 'none');
    });

    test('keeps identity fields untouched', () {
      final j = applyCoverTheme(_journal(), coverThemes.first);
      expect(j.journalId, 'j1');
      expect(j.ownerId, 'u1');
      expect(j.title, '나의 일기장');
      expect(j.type, JournalType.personal);
    });
  });

  group('coverThemes', () {
    test('has unique ids', () {
      final ids = coverThemes.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every theme uses valid layer ids', () {
      const textures = {'none', 'leather', 'kraft', 'fabric', 'cork', 'wood'};
      const bindings = {'plain', 'spiral', 'ring', 'stitch', 'staple', 'disc'};
      const corners = {'none', 'photo', 'tape', 'fold'};
      const bands = {'none', 'band', 'buckle', 'double'};
      const ribbons = {'none', 'red', 'gold', 'pink'};
      const clips = {'none', 'silver', 'gold', 'pink'};
      const tabs = {'none', 'colorful', 'pink', 'blue'};
      for (final t in coverThemes) {
        expect(textures, contains(t.texture), reason: '${t.id} texture');
        expect(bindings, contains(t.binding), reason: '${t.id} binding');
        expect(corners, contains(t.corner), reason: '${t.id} corner');
        expect(bands, contains(t.band), reason: '${t.id} band');
        expect(ribbons, contains(t.ribbon), reason: '${t.id} ribbon');
        expect(clips, contains(t.clip), reason: '${t.id} clip');
        expect(tabs, contains(t.tab), reason: '${t.id} tab');
        expect(t.label, isNotEmpty);
        expect(t.icon, isNotEmpty);
      }
    });
  });
}
