import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/features/stats/mood_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry(
  String id, {
  Mood? mood,
  String? replyTo,
  DateTime? created,
}) {
  final ts = created ?? DateTime(2026, 6, 1);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    replyToEntryId: replyTo,
    content: id,
    mood: mood,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('moodFromName', () {
    test('resolves each stable name', () {
      expect(moodFromName('good'), Mood.good);
      expect(moodFromName('neutral'), Mood.neutral);
      expect(moodFromName('hard'), Mood.hard);
    });

    test('unknown or blank yields null', () {
      expect(moodFromName(''), isNull);
      expect(moodFromName('😊'), isNull);
      expect(moodFromName('great'), isNull);
    });
  });

  group('moodCountsSorted', () {
    test('counts top-level entries per mood, most-recorded first', () {
      final entries = [
        _entry('a', mood: Mood.good),
        _entry('b', mood: Mood.good),
        _entry('c', mood: Mood.hard),
        _entry('d', mood: Mood.good),
        _entry('e', mood: Mood.hard),
      ];
      final result = moodCountsSorted(entries);
      expect(result.map((e) => e.key), [Mood.good, Mood.hard]);
      expect(result.map((e) => e.value), [3, 2]);
    });

    test('excludes replies and moodless entries', () {
      final entries = [
        _entry('a', mood: Mood.good),
        _entry('b'), // no mood
        _entry('c', mood: Mood.hard, replyTo: 'a'), // reply excluded
      ];
      final result = moodCountsSorted(entries);
      expect(result.map((e) => e.key), [Mood.good]);
      expect(result.single.value, 1);
    });

    test('ties resolve to earlier Mood.values order', () {
      final entries = [
        _entry('a', mood: Mood.hard),
        _entry('b', mood: Mood.neutral),
        _entry('c', mood: Mood.good),
      ];
      // all tied at 1 → good, neutral, hard
      expect(
        moodCountsSorted(entries).map((e) => e.key),
        [Mood.good, Mood.neutral, Mood.hard],
      );
    });

    test('empty when nothing recorded', () {
      expect(moodCountsSorted([_entry('a')]), isEmpty);
      expect(moodCountsSorted(const []), isEmpty);
    });
  });

  group('entriesWithMood', () {
    test('keeps only top-level entries of the given mood', () {
      final entries = [
        _entry('a', mood: Mood.good),
        _entry('b', mood: Mood.hard),
        _entry('c', mood: Mood.good),
        _entry('d'), // no mood
        _entry('e', mood: Mood.good, replyTo: 'a'), // reply excluded
      ];
      final good = entriesWithMood(entries, Mood.good);
      expect(good.map((e) => e.entryId), ['a', 'c']);
    });

    test('returns newest first', () {
      final entries = [
        _entry('old', mood: Mood.good, created: DateTime(2026, 1, 1)),
        _entry('new', mood: Mood.good, created: DateTime(2026, 6, 1)),
        _entry('mid', mood: Mood.good, created: DateTime(2026, 3, 1)),
      ];
      expect(
        entriesWithMood(entries, Mood.good).map((e) => e.entryId),
        ['new', 'mid', 'old'],
      );
    });

    test('empty when no entry matches', () {
      final entries = [_entry('a', mood: Mood.good)];
      expect(entriesWithMood(entries, Mood.hard), isEmpty);
    });
  });
}
