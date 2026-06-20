import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/entry_detail/entry_neighbors.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _e(String id, int day, {String journalId = 'j1', String? replyTo}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: journalId,
      replyToEntryId: replyTo,
      content: 'x',
      createdAt: DateTime(2026, 6, day),
      updatedAt: DateTime(2026, 6, day),
    );

void main() {
  group('adjacentEntries', () {
    final entries = [
      _e('a', 10),
      _e('b', 12),
      _e('c', 15),
    ];

    test('middle entry has both neighbours', () {
      final n = adjacentEntries(entries, 'b');
      expect(n.previous?.entryId, 'a'); // older
      expect(n.next?.entryId, 'c'); // newer
    });

    test('oldest has no previous', () {
      final n = adjacentEntries(entries, 'a');
      expect(n.previous, isNull);
      expect(n.next?.entryId, 'b');
    });

    test('newest has no next', () {
      final n = adjacentEntries(entries, 'c');
      expect(n.previous?.entryId, 'b');
      expect(n.next, isNull);
    });

    test('unknown id returns nulls', () {
      final n = adjacentEntries(entries, 'zzz');
      expect(n.previous, isNull);
      expect(n.next, isNull);
    });

    test('scoped to the same journal', () {
      final mixed = [
        _e('a', 10, journalId: 'j1'),
        _e('x', 11, journalId: 'j2'),
        _e('b', 12, journalId: 'j1'),
      ];
      final n = adjacentEntries(mixed, 'a');
      expect(n.next?.entryId, 'b'); // skips j2 entry
      expect(n.previous, isNull);
    });

    test('replies are ignored', () {
      final withReply = [
        _e('a', 10),
        _e('r', 11, replyTo: 'a'),
        _e('b', 12),
      ];
      final n = adjacentEntries(withReply, 'a');
      expect(n.next?.entryId, 'b');
    });
  });
}
