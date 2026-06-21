import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/lifetime_stats.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  String content = 'c',
  required DateTime at,
  String? replyTo,
  List<String> tags = const [],
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: 'jr_default',
      content: content,
      tags: tags,
      replyToEntryId: replyTo,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  test('empty → all zero and no first date', () {
    final s = computeLifetimeStats(const []);
    expect(s.isEmpty, true);
    expect(s.totalEntries, 0);
    expect(s.firstDate, isNull);
  });

  test('aggregates totals and excludes replies', () {
    final s = computeLifetimeStats([
      _entry(id: 'a', content: '제주', at: DateTime(2026, 6, 1)), // 2 chars
      _entry(id: 'b', content: 'hello', at: DateTime(2026, 6, 2)), // 5 chars
      _entry(id: 'r', content: 'reply', at: DateTime(2026, 6, 3), replyTo: 'a'),
    ]);
    expect(s.totalEntries, 2);
    expect(s.totalChars, 7);
    expect(s.recordedDays, 2);
  });

  test('firstDate is the earliest top-level day (time stripped)', () {
    final s = computeLifetimeStats([
      _entry(id: 'late', at: DateTime(2026, 6, 10, 9)),
      _entry(id: 'early', at: DateTime(2026, 6, 2, 23, 59)),
    ]);
    expect(s.firstDate, DateTime(2026, 6, 2));
  });

  test('longestStreak counts consecutive recorded days', () {
    final s = computeLifetimeStats([
      _entry(id: '1', at: DateTime(2026, 6, 1)),
      _entry(id: '2', at: DateTime(2026, 6, 2)),
      _entry(id: '3', at: DateTime(2026, 6, 3)),
      _entry(id: '5', at: DateTime(2026, 6, 5)),
    ]);
    expect(s.longestStreak, 3);
  });

  group('avgCharsPerEntry', () {
    test('zero when there are no records', () {
      expect(computeLifetimeStats(const []).avgCharsPerEntry, 0);
    });

    test('rounds the mean body length, excluding replies', () {
      final s = computeLifetimeStats([
        _entry(id: 'a', content: '12345', at: DateTime(2026, 6, 1)), // 5
        _entry(id: 'b', content: '12', at: DateTime(2026, 6, 2)), // 2
        _entry(id: 'r', content: 'xxxx', at: DateTime(2026, 6, 3), replyTo: 'a'),
      ]);
      // (5 + 2) / 2 = 3.5 → rounds to 4
      expect(s.avgCharsPerEntry, 4);
    });
  });

  group('topTags', () {
    test('empty when no tags', () {
      expect(topTags(const []), isEmpty);
      expect(topTags([_entry(id: 'a', at: DateTime(2026, 6, 1))]), isEmpty);
    });

    test('sorts by frequency desc, ties alphabetically', () {
      final tags = topTags([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행', '가족']),
        _entry(id: 'b', at: DateTime(2026, 6, 2), tags: ['여행', '일상']),
        _entry(id: 'c', at: DateTime(2026, 6, 3), tags: ['여행']),
      ]);
      expect(tags.map((e) => e.key).toList(), ['여행', '가족', '일상']);
      expect(tags.first.value, 3);
      // 가족 vs 일상 both count 1 → alphabetical (가 < 일)
      expect(tags[1].key, '가족');
    });

    test('excludes replies', () {
      final tags = topTags([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['여행']),
        _entry(id: 'r', at: DateTime(2026, 6, 2), tags: ['여행'], replyTo: 'a'),
      ]);
      expect(tags.single.value, 1);
    });

    test('respects the limit', () {
      final tags = topTags([
        _entry(id: 'a', at: DateTime(2026, 6, 1), tags: ['a', 'b', 'c', 'd']),
      ], limit: 2);
      expect(tags.length, 2);
    });
  });

  group('recentMonthlyCounts', () {
    test('returns the trailing N months oldest-first ending in now', () {
      final t = recentMonthlyCounts(const [], DateTime(2026, 6, 15), months: 3);
      expect(t.map((m) => '${m.year}-${m.month}').toList(),
          ['2026-4', '2026-5', '2026-6']);
      expect(t.every((m) => m.count == 0), true);
    });

    test('crosses the year boundary correctly', () {
      final t = recentMonthlyCounts(const [], DateTime(2026, 2, 1), months: 4);
      expect(t.map((m) => '${m.year}-${m.month}').toList(),
          ['2025-11', '2025-12', '2026-1', '2026-2']);
    });

    test('counts top-level entries per month, excludes replies & old months',
        () {
      final t = recentMonthlyCounts([
        _entry(id: 'a', at: DateTime(2026, 6, 3)),
        _entry(id: 'b', at: DateTime(2026, 6, 20)),
        _entry(id: 'r', at: DateTime(2026, 6, 21), replyTo: 'a'),
        _entry(id: 'c', at: DateTime(2026, 5, 9)),
        _entry(id: 'old', at: DateTime(2025, 1, 1)), // outside window
      ], DateTime(2026, 6, 30), months: 6);
      final june = t.firstWhere((m) => m.month == 6);
      final may = t.firstWhere((m) => m.month == 5);
      expect(june.count, 2);
      expect(may.count, 1);
    });

    test('months <= 0 gives empty', () {
      expect(recentMonthlyCounts(const [], DateTime(2026, 6, 1), months: 0),
          isEmpty);
    });
  });
}
