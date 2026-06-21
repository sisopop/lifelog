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
