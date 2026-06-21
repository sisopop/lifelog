import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/review/day_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  String? replyTo,
  Mood? mood,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      replyToEntryId: replyTo,
      content: 'x',
      mood: mood,
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

  group('dominantMoodOf', () {
    test('returns the most-recorded mood', () {
      final m = dominantMoodOf([
        _e(id: '1', at: DateTime(2026, 6, 1), mood: Mood.good),
        _e(id: '2', at: DateTime(2026, 6, 1), mood: Mood.good),
        _e(id: '3', at: DateTime(2026, 6, 1), mood: Mood.hard),
      ]);
      expect(m, Mood.good);
    });

    test('ties resolve to the earlier mood in enum order', () {
      final m = dominantMoodOf([
        _e(id: '1', at: DateTime(2026, 6, 1), mood: Mood.hard),
        _e(id: '2', at: DateTime(2026, 6, 1), mood: Mood.good),
      ]);
      expect(m, Mood.good);
    });

    test('ignores moodless records', () {
      final m = dominantMoodOf([
        _e(id: '1', at: DateTime(2026, 6, 1), mood: Mood.neutral),
        _e(id: '2', at: DateTime(2026, 6, 1)),
      ]);
      expect(m, Mood.neutral);
    });

    test('null when nothing carries a mood', () {
      expect(dominantMoodOf([_e(id: '1', at: DateTime(2026, 6, 1))]), isNull);
      expect(dominantMoodOf(const []), isNull);
    });
  });
}
