import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/favorites/favorite_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  bool isFavorite = false,
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      replyToEntryId: replyTo,
      isFavorite: isFavorite,
      content: 'x',
      createdAt: at,
      updatedAt: at,
    );

void main() {
  group('favoriteEntries', () {
    test('keeps only starred top-level entries, newest first', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 1), isFavorite: true),
        _e(id: '2', at: DateTime(2026, 6, 5), isFavorite: true),
        _e(id: '3', at: DateTime(2026, 6, 3), isFavorite: false),
      ];
      final r = favoriteEntries(entries);
      expect(r.map((e) => e.entryId), ['2', '1']);
    });

    test('excludes replies even when starred', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 1), isFavorite: true),
        _e(id: '2', at: DateTime(2026, 6, 2), isFavorite: true, replyTo: '1'),
      ];
      expect(favoriteEntries(entries).map((e) => e.entryId), ['1']);
    });

    test('empty when nothing is starred', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 1)),
        _e(id: '2', at: DateTime(2026, 6, 2)),
      ];
      expect(favoriteEntries(entries), isEmpty);
    });

    test('ascending gives oldest-first', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 1), isFavorite: true),
        _e(id: '2', at: DateTime(2026, 6, 5), isFavorite: true),
        _e(id: '3', at: DateTime(2026, 6, 3), isFavorite: true),
      ];
      expect(favoriteEntries(entries, ascending: true).map((e) => e.entryId),
          ['1', '3', '2']);
    });

    test('does not mutate the input list', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 1), isFavorite: true),
        _e(id: '2', at: DateTime(2026, 6, 5), isFavorite: true),
      ];
      favoriteEntries(entries, ascending: true);
      expect(entries.map((e) => e.entryId), ['1', '2']);
    });
  });
}
