import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/tags/tag_entries.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  List<String> tags = const [],
  String? replyTo,
  Mood? mood,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'j1',
      replyToEntryId: replyTo,
      content: 'x',
      tags: tags,
      mood: mood,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  final entries = [
    _e(id: '1', at: DateTime(2026, 6, 10), tags: ['여행', '가족']),
    _e(id: '2', at: DateTime(2026, 6, 15), tags: ['여행']), // newer
    _e(id: '3', at: DateTime(2026, 6, 12), tags: ['여행'], replyTo: '1'), // reply
    _e(id: '4', at: DateTime(2026, 6, 11), tags: ['일']),
  ];

  test('returns top-level entries with the tag, newest first', () {
    final r = entriesWithTag(entries, '여행');
    expect(r.map((e) => e.entryId), ['2', '1']);
  });

  test('matches any of an entry\'s tags', () {
    final r = entriesWithTag(entries, '가족');
    expect(r.map((e) => e.entryId), ['1']);
  });

  test('empty when no entry carries the tag', () {
    expect(entriesWithTag(entries, '운동'), isEmpty);
  });

  group('coOccurringTags', () {
    test('counts tags sharing a record with the target, by frequency', () {
      final r = coOccurringTags([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행', '가족']),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행', '가족']),
        _e(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행', '맛집']),
        _e(id: 'd', at: DateTime(2026, 6, 4), tags: ['일상']), // no overlap
      ], '여행');
      expect(r.map((e) => e.key).toList(), ['가족', '맛집']);
      expect(r.first.value, 2);
    });

    test('excludes the target tag itself and replies', () {
      final r = coOccurringTags([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행', '가족']),
        _e(id: 'r', at: DateTime(2026, 6, 2), tags: ['여행', '가족'], replyTo: 'a'),
      ], '여행');
      expect(r.length, 1);
      expect(r.single.key, '가족');
      expect(r.single.value, 1); // reply not counted
    });

    test('ties resolve alphabetically and respect the limit', () {
      final r = coOccurringTags([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행', '다', '나', '가']),
      ], '여행', limit: 2);
      expect(r.map((e) => e.key).toList(), ['가', '나']);
    });

    test('empty when nothing co-occurs', () {
      final r = coOccurringTags([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행']),
      ], '여행');
      expect(r, isEmpty);
    });
  });

  group('tagDateSpan', () {
    test('earliest and latest date-only, replies excluded', () {
      final s = tagDateSpan(entries, '여행');
      expect(s!.first, DateTime(2026, 6, 10));
      expect(s.last, DateTime(2026, 6, 15));
    });

    test('drops the time component to date-only', () {
      final s = tagDateSpan([
        _e(id: '1', at: DateTime(2026, 6, 10, 23, 59), tags: ['여행']),
      ], '여행');
      expect(s!.first, DateTime(2026, 6, 10));
      expect(s.first, s.last);
    });

    test('null when the tag has no top-level records', () {
      expect(tagDateSpan(entries, '운동'), isNull);
      // a tag that appears only on a reply
      expect(
        tagDateSpan([
          _e(id: 'r', at: DateTime(2026, 6, 1), tags: ['답'], replyTo: 'x'),
        ], '답'),
        isNull,
      );
    });
  });

  group('tagMood', () {
    test('most frequent mood, replies excluded', () {
      final m = tagMood([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], mood: Mood.good),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행'], mood: Mood.good),
        _e(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행'], mood: Mood.hard),
        _e(
            id: 'r',
            at: DateTime(2026, 6, 4),
            tags: ['여행'],
            mood: Mood.hard,
            replyTo: 'a'),
        _e(id: 'o', at: DateTime(2026, 6, 5), tags: ['일'], mood: Mood.hard),
      ], '여행');
      expect(m, Mood.good);
    });

    test('ties resolve to the earlier Mood.values entry', () {
      final m = tagMood([
        _e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'], mood: Mood.hard),
        _e(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행'], mood: Mood.good),
      ], '여행');
      expect(m, Mood.good);
    });

    test('null when the tag has no records with a mood', () {
      expect(
          tagMood([_e(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행'])], '여행'),
          isNull);
      expect(tagMood(entries, '운동'), isNull);
    });
  });
}
