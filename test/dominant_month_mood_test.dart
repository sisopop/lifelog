import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/stats_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry({
  required String id,
  required int month,
  required int day,
  Mood? mood,
  String? replyTo,
}) {
  final t = DateTime(2026, month, day);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    content: 'c',
    mood: mood,
    replyToEntryId: replyTo,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('dominantMonthMood', () {
    test('returns the most-recorded mood of the month', () {
      final m = dominantMonthMood([
        _entry(id: '1', month: 6, day: 3, mood: Mood.good),
        _entry(id: '2', month: 6, day: 5, mood: Mood.good),
        _entry(id: '3', month: 6, day: 7, mood: Mood.hard),
      ], 2026, 6);
      expect(m, Mood.good);
    });

    test('only counts the given month', () {
      final m = dominantMonthMood([
        _entry(id: '1', month: 6, day: 3, mood: Mood.neutral),
        _entry(id: '2', month: 5, day: 9, mood: Mood.hard),
        _entry(id: '3', month: 5, day: 10, mood: Mood.hard),
      ], 2026, 6);
      expect(m, Mood.neutral);
    });

    test('ties resolve to the earlier mood in enum order', () {
      final m = dominantMonthMood([
        _entry(id: '1', month: 6, day: 3, mood: Mood.hard),
        _entry(id: '2', month: 6, day: 5, mood: Mood.good),
      ], 2026, 6);
      expect(m, Mood.good); // good comes before hard in Mood.values
    });

    test('excludes replies and moodless records', () {
      final m = dominantMonthMood([
        _entry(id: 'top', month: 6, day: 3, mood: Mood.hard),
        _entry(id: 'reply', month: 6, day: 3, mood: Mood.good, replyTo: 'top'),
        _entry(id: 'reply2', month: 6, day: 4, mood: Mood.good, replyTo: 'top'),
        _entry(id: 'none', month: 6, day: 5, mood: null),
      ], 2026, 6);
      expect(m, Mood.hard); // only the one top-level mood counts
    });

    test('null when the month has no records with a mood', () {
      final m = dominantMonthMood([
        _entry(id: '1', month: 6, day: 3, mood: null),
        _entry(id: '2', month: 5, day: 3, mood: Mood.good),
      ], 2026, 6);
      expect(m, isNull);
    });
  });
}
