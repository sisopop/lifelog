import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/memories/random_memory.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry(String id, DateTime createdAt, {String? replyTo}) {
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c-$id',
    createdAt: createdAt,
    updatedAt: createdAt,
    replyToEntryId: replyTo,
  );
}

void main() {
  final today = DateTime(2026, 6, 21);

  group('resurfaceableEntries', () {
    test('keeps only top-level entries strictly before today', () {
      final entries = [
        _entry('a', DateTime(2026, 6, 12)),
        _entry('b', DateTime(2026, 6, 17)),
        _entry('today', DateTime(2026, 6, 21, 9)), // today → excluded
        _entry('future', DateTime(2026, 6, 25)), // after → excluded
        _entry('reply', DateTime(2026, 6, 10), replyTo: 'a'), // reply → excluded
      ];
      final out = resurfaceableEntries(entries, today);
      expect(out.map((e) => e.entryId), ['b', 'a']); // newest first
    });

    test('is empty when there is nothing in the past', () {
      final entries = [_entry('today', DateTime(2026, 6, 21))];
      expect(resurfaceableEntries(entries, today), isEmpty);
    });
  });

  group('pickRandomMemory', () {
    final entries = [
      _entry('a', DateTime(2026, 6, 12)),
      _entry('b', DateTime(2026, 6, 17)),
      _entry('c', DateTime(2026, 6, 19)),
    ];

    test('returns null when there are no past entries', () {
      expect(pickRandomMemory(const [], today, 0), isNull);
    });

    test('is deterministic for a given seed', () {
      expect(
        pickRandomMemory(entries, today, 5)?.entryId,
        pickRandomMemory(entries, today, 5)?.entryId,
      );
    });

    test('cycles through the pool as the seed increments', () {
      // pool order is newest first: [c, b, a]
      expect(pickRandomMemory(entries, today, 0)?.entryId, 'c');
      expect(pickRandomMemory(entries, today, 1)?.entryId, 'b');
      expect(pickRandomMemory(entries, today, 2)?.entryId, 'a');
      expect(pickRandomMemory(entries, today, 3)?.entryId, 'c'); // wraps
    });
  });
}
