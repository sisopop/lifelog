import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/review/day_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      replyToEntryId: replyTo,
      content: 'x',
      createdAt: at,
      updatedAt: at,
    );

void main() {
  final entries = [
    _e(id: '1', at: DateTime(2026, 6, 12, 9)),
    _e(id: '2', at: DateTime(2026, 6, 12, 21)), // later same day
    _e(id: '3', at: DateTime(2026, 6, 12, 14), replyTo: '1'), // reply excluded
    _e(id: '4', at: DateTime(2026, 6, 13, 8)), // other day
  ];

  test('returns top-level entries of the day, newest first', () {
    final r = entriesOfDay(entries, DateTime(2026, 6, 12));
    expect(r.map((e) => e.entryId), ['2', '1']);
  });

  test('time component of the query day is ignored', () {
    final r = entriesOfDay(entries, DateTime(2026, 6, 12, 23, 59));
    expect(r.length, 2);
  });

  test('empty when no entries on that day', () {
    expect(entriesOfDay(entries, DateTime(2026, 6, 1)), isEmpty);
  });
}
