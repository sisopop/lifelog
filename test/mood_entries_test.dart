import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/features/stats/mood_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _entry(
  String id, {
  Mood? mood,
  String? replyTo,
  DateTime? created,
  List<String> tags = const [],
  String? location,
}) {
  final ts = created ?? DateTime(2026, 6, 1);
  return DiaryEntry(
    entryId: id,
    userId: 'me',
    journalId: 'jr_default',
    replyToEntryId: replyTo,
    content: id,
    mood: mood,
    tags: tags,
    location: location,
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

  group('lastUseByMood', () {
    test('keeps the most recent created date per mood', () {
      final entries = [
        _entry('a', mood: Mood.good, created: DateTime(2026, 1, 1)),
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 1)),
        _entry('c', mood: Mood.hard, created: DateTime(2026, 3, 1)),
      ];
      final last = lastUseByMood(entries);
      expect(last[Mood.good], DateTime(2026, 6, 1));
      expect(last[Mood.hard], DateTime(2026, 3, 1));
    });

    test('excludes replies and moodless entries', () {
      final entries = [
        _entry('a', mood: Mood.good, created: DateTime(2026, 1, 1)),
        _entry('b', created: DateTime(2026, 6, 1)), // no mood
        _entry('c', mood: Mood.good, replyTo: 'a', created: DateTime(2026, 6, 1)),
      ];
      final last = lastUseByMood(entries);
      expect(last[Mood.good], DateTime(2026, 1, 1));
      expect(last.length, 1);
    });

    test('empty when nothing recorded', () {
      expect(lastUseByMood(const []), isEmpty);
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

  group('moodDateSpan', () {
    test('earliest and latest date-only, replies & other moods excluded', () {
      final s = moodDateSpan([
        _entry('a', mood: Mood.good, created: DateTime(2026, 6, 10, 23, 59)),
        _entry('b', mood: Mood.good, created: DateTime(2026, 6, 20, 1, 0)),
        _entry('r',
            mood: Mood.good, replyTo: 'a', created: DateTime(2026, 6, 25)),
        _entry('h', mood: Mood.hard, created: DateTime(2026, 6, 5)),
      ], Mood.good);
      expect(s!.first, DateTime(2026, 6, 10));
      expect(s.last, DateTime(2026, 6, 20));
    });

    test('single record spans that one date', () {
      final s = moodDateSpan(
          [_entry('a', mood: Mood.good, created: DateTime(2026, 6, 13))],
          Mood.good);
      expect(s!.first, DateTime(2026, 6, 13));
      expect(s.first, s.last);
    });

    test('null when the mood has no top-level records', () {
      expect(
          moodDateSpan([_entry('a', mood: Mood.good)], Mood.hard), isNull);
      expect(
        moodDateSpan([
          _entry('r', mood: Mood.good, replyTo: 'x'),
        ], Mood.good),
        isNull,
      );
    });
  });

  group('tagsWithMood', () {
    test('counts tags for the mood by frequency, replies & other mood excluded',
        () {
      final r = tagsWithMood([
        _entry('a', mood: Mood.good, tags: ['여행', '가족']),
        _entry('b', mood: Mood.good, tags: ['여행']),
        _entry('r', mood: Mood.good, tags: ['여행'], replyTo: 'a'), // reply
        _entry('h', mood: Mood.hard, tags: ['일']), // other mood
      ], Mood.good);
      expect(r.map((e) => e.key).toList(), ['여행', '가족']);
      expect(r.first.value, 2);
    });

    test('ties resolve alphabetically and respect the limit', () {
      final r = tagsWithMood([
        _entry('a', mood: Mood.good, tags: ['다', '나', '가']),
      ], Mood.good, limit: 2);
      expect(r.map((e) => e.key).toList(), ['가', '나']);
    });

    test('empty when no matching record carries a tag', () {
      expect(tagsWithMood([_entry('a', mood: Mood.good)], Mood.good), isEmpty);
      expect(
          tagsWithMood([_entry('a', mood: Mood.hard, tags: ['x'])], Mood.good),
          isEmpty);
    });
  });

  group('placesWithMood', () {
    test('counts places for the mood, replies & other mood & blanks excluded',
        () {
      final r = placesWithMood([
        _entry('a', mood: Mood.good, location: '제주'),
        _entry('b', mood: Mood.good, location: '제주'),
        _entry('c', mood: Mood.good, location: '서울'),
        _entry('d', mood: Mood.good, location: '  '), // blank ignored
        _entry('r', mood: Mood.good, location: '제주', replyTo: 'a'), // reply
        _entry('h', mood: Mood.hard, location: '부산'), // other mood
      ], Mood.good);
      expect(r, ['제주', '서울']);
    });

    test('ties resolve alphabetically and respect the limit', () {
      final r = placesWithMood([
        _entry('a', mood: Mood.good, location: '다'),
        _entry('b', mood: Mood.good, location: '나'),
        _entry('c', mood: Mood.good, location: '가'),
      ], Mood.good, limit: 2);
      expect(r, ['가', '나']);
    });

    test('empty when no matching record carries a place', () {
      expect(placesWithMood([_entry('a', mood: Mood.good)], Mood.good), isEmpty);
      expect(
          placesWithMood(
              [_entry('a', mood: Mood.hard, location: '제주')], Mood.good),
          isEmpty);
    });
  });
}
