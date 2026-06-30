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

  group('entryOrdinal', () {
    final entries = [
      _e('a', 10),
      _e('b', 12),
      _e('c', 15),
    ];

    test('oldest is 1st, newest is last', () {
      expect(entryOrdinal(entries, 'a')!.position, 1);
      expect(entryOrdinal(entries, 'c')!.position, 3);
      expect(entryOrdinal(entries, 'a')!.total, 3);
    });

    test('middle entry has the right position', () {
      final o = entryOrdinal(entries, 'b')!;
      expect(o.position, 2);
      expect(o.total, 3);
    });

    test('scopes to the same journal and total', () {
      final mixed = [
        _e('a', 10, journalId: 'j1'),
        _e('x', 11, journalId: 'j2'),
        _e('b', 12, journalId: 'j1'),
      ];
      final o = entryOrdinal(mixed, 'b')!;
      expect(o.position, 2); // a then b within j1
      expect(o.total, 2); // j2 entry excluded
    });

    test('ignores replies in position and total', () {
      final withReply = [
        _e('a', 10),
        _e('r', 11, replyTo: 'a'),
        _e('b', 12),
      ];
      final o = entryOrdinal(withReply, 'b')!;
      expect(o.position, 2);
      expect(o.total, 2);
    });

    test('null when the entry is missing', () {
      expect(entryOrdinal(entries, 'ghost'), isNull);
    });
  });

  group('nextEntryOrdinal', () {
    test('empty journal starts at 1', () {
      expect(nextEntryOrdinal(const [], 'j1'), 1);
    });

    test('one past the journal top-level count', () {
      final entries = [_e('a', 10), _e('b', 12), _e('c', 15)];
      expect(nextEntryOrdinal(entries, 'j1'), 4);
    });

    test('scoped to the journal', () {
      final mixed = [
        _e('a', 10, journalId: 'j1'),
        _e('x', 11, journalId: 'j2'),
        _e('b', 12, journalId: 'j1'),
      ];
      expect(nextEntryOrdinal(mixed, 'j1'), 3); // 2 in j1 → next is 3rd
      expect(nextEntryOrdinal(mixed, 'j2'), 2); // 1 in j2 → next is 2nd
    });

    test('replies are ignored', () {
      final withReply = [
        _e('a', 10),
        _e('r', 11, replyTo: 'a'),
        _e('b', 12),
      ];
      expect(nextEntryOrdinal(withReply, 'j1'), 3); // r excluded
    });
  });
}
