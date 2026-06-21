import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/stats/stats_provider.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

DiaryEntry _e({
  required String id,
  required DateTime at,
  Mood? mood,
  List<String> tags = const [],
  String? replyTo,
  String journalId = 'j1',
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: journalId,
      replyToEntryId: replyTo,
      mood: mood,
      tags: tags,
      content: 'x',
      createdAt: at,
      updatedAt: at,
    );

void main() {
  group('computeMonthlyStats', () {
    final entries = [
      _e(id: '1', at: DateTime(2026, 6, 1), mood: Mood.good, tags: ['여행', '가족']),
      _e(id: '2', at: DateTime(2026, 6, 1), mood: Mood.good, tags: ['여행']),
      _e(id: '3', at: DateTime(2026, 6, 12), mood: Mood.hard, tags: ['일']),
      _e(id: '4', at: DateTime(2026, 6, 12), mood: Mood.good, replyTo: '1'),
      _e(id: '5', at: DateTime(2026, 5, 30), mood: Mood.neutral),
    ];

    test('counts only the target month, top-level only', () {
      final s = computeMonthlyStats(entries, 2026, 6);
      expect(s.total, 3); // reply (#4) excluded, May (#5) excluded
      expect(s.daysRecorded, 2); // day 1 and day 12
    });

    test('mood ratios sum over the month total', () {
      final s = computeMonthlyStats(entries, 2026, 6);
      expect(s.moodRatio[Mood.good], closeTo(2 / 3, 1e-9));
      expect(s.moodRatio[Mood.hard], closeTo(1 / 3, 1e-9));
      expect(s.moodRatio[Mood.neutral], 0);
    });

    test('top tags ranked by usage', () {
      final s = computeMonthlyStats(entries, 2026, 6);
      expect(s.topTags.first.key, '여행');
      expect(s.topTags.first.value, 2);
    });

    test('empty month yields isEmpty', () {
      final s = computeMonthlyStats(entries, 2026, 1);
      expect(s.isEmpty, true);
      expect(s.total, 0);
    });
  });

  group('monthEntryCount', () {
    final entries = [
      _e(id: '1', at: DateTime(2026, 6, 1)),
      _e(id: '2', at: DateTime(2026, 6, 20)),
      _e(id: '3', at: DateTime(2026, 6, 20), replyTo: '2'), // reply excluded
      _e(id: '4', at: DateTime(2026, 5, 30)), // other month
    ];

    test('counts top-level entries of the target month only', () {
      expect(monthEntryCount(entries, 2026, 6), 2);
      expect(monthEntryCount(entries, 2026, 5), 1);
    });

    test('zero for a month with no records', () {
      expect(monthEntryCount(entries, 2026, 1), 0);
      expect(monthEntryCount(const [], 2026, 6), 0);
    });
  });

  group('monthOverMonthDelta', () {
    final entries = [
      _e(id: '1', at: DateTime(2026, 6, 1)),
      _e(id: '2', at: DateTime(2026, 6, 20)),
      _e(id: '3', at: DateTime(2026, 6, 20), replyTo: '2'), // reply excluded
      _e(id: '4', at: DateTime(2026, 5, 10)),
    ];

    test('positive when the month has more than the previous', () {
      // June: 2 top-level, May: 1 → +1
      expect(monthOverMonthDelta(entries, 2026, 6), 1);
    });

    test('negative when the month has fewer than the previous', () {
      final shrinking = [
        _e(id: 'a', at: DateTime(2026, 6, 1)),
        _e(id: 'b', at: DateTime(2026, 5, 1)),
        _e(id: 'c', at: DateTime(2026, 5, 12)),
        _e(id: 'd', at: DateTime(2026, 5, 20)),
      ];
      // June: 1, May: 3 → -2
      expect(monthOverMonthDelta(shrinking, 2026, 6), -2);
    });

    test('zero when both months match', () {
      final flat = [
        _e(id: 'a', at: DateTime(2026, 6, 1)),
        _e(id: 'b', at: DateTime(2026, 5, 1)),
      ];
      expect(monthOverMonthDelta(flat, 2026, 6), 0);
    });

    test('rolls back across the year boundary (Jan vs prev Dec)', () {
      final yb = [
        _e(id: 'a', at: DateTime(2026, 1, 5)),
        _e(id: 'b', at: DateTime(2025, 12, 5)),
        _e(id: 'c', at: DateTime(2025, 12, 20)),
      ];
      // Jan 1 vs Dec 2 → -1
      expect(monthOverMonthDelta(yb, 2026, 1), -1);
    });
  });

  group('monthlyAverageGapDays', () {
    test('null with fewer than two distinct days in the month', () {
      expect(monthlyAverageGapDays(const [], 2026, 6), isNull);
      expect(
          monthlyAverageGapDays(
              [_e(id: 'a', at: DateTime(2026, 6, 3))], 2026, 6),
          isNull);
      // same calendar day twice still counts as one day
      expect(
          monthlyAverageGapDays([
            _e(id: 'a', at: DateTime(2026, 6, 3, 9)),
            _e(id: 'b', at: DateTime(2026, 6, 3, 20)),
          ], 2026, 6),
          isNull);
    });

    test('averages gaps between distinct recorded days in the month', () {
      // days 6/2, 6/6, 6/14 → span 12 over 2 gaps → 6
      final r = monthlyAverageGapDays([
        _e(id: 'a', at: DateTime(2026, 6, 2)),
        _e(id: 'b', at: DateTime(2026, 6, 6)),
        _e(id: 'c', at: DateTime(2026, 6, 14)),
      ], 2026, 6);
      expect(r, 6);
    });

    test('ignores replies and other months', () {
      // top-level on 6/1 and 6/5 → span 4 / 1 gap = 4
      final r = monthlyAverageGapDays([
        _e(id: 'a', at: DateTime(2026, 6, 1)),
        _e(id: 'b', at: DateTime(2026, 6, 5)),
        _e(id: 'r', at: DateTime(2026, 6, 20), replyTo: 'a'),
        _e(id: 'm', at: DateTime(2026, 5, 10)),
      ], 2026, 6);
      expect(r, 4);
    });
  });

  group('recordedDaysOfMonth', () {
    final entries = [
      _e(id: '1', at: DateTime(2026, 6, 1)),
      _e(id: '2', at: DateTime(2026, 6, 1)), // same day → one entry in set
      _e(id: '3', at: DateTime(2026, 6, 12)),
      _e(id: '4', at: DateTime(2026, 6, 12), replyTo: '3'), // reply excluded
      _e(id: '5', at: DateTime(2026, 5, 30)), // other month
    ];

    test('returns distinct top-level days of the target month', () {
      expect(recordedDaysOfMonth(entries, 2026, 6), {1, 12});
    });

    test('empty for a month with no records', () {
      expect(recordedDaysOfMonth(entries, 2026, 1), isEmpty);
    });
  });

  group('ReviewMonth navigation', () {
    test('previous rolls back across year boundary', () {
      expect(const ReviewMonth(2026, 1).previous, const ReviewMonth(2025, 12));
      expect(const ReviewMonth(2026, 6).previous, const ReviewMonth(2026, 5));
    });

    test('next rolls forward across year boundary', () {
      expect(const ReviewMonth(2026, 12).next, const ReviewMonth(2027, 1));
      expect(const ReviewMonth(2026, 6).next, const ReviewMonth(2026, 7));
    });

    test('isAtOrAfter compares chronologically', () {
      const now = ReviewMonth(2026, 6);
      expect(const ReviewMonth(2026, 6).isAtOrAfter(now), true);
      expect(const ReviewMonth(2026, 7).isAtOrAfter(now), true);
      expect(const ReviewMonth(2026, 5).isAtOrAfter(now), false);
      expect(const ReviewMonth(2025, 12).isAtOrAfter(now), false);
    });
  });

  group('filterEntriesByJournal', () {
    final entries = [
      _e(id: '1', at: DateTime(2026, 6, 1), journalId: 'j1'),
      _e(id: '2', at: DateTime(2026, 6, 2), journalId: 'j2'),
      _e(id: '3', at: DateTime(2026, 6, 3), journalId: 'j1'),
    ];

    test('null returns all entries unchanged', () {
      expect(filterEntriesByJournal(entries, null), entries);
    });

    test('keeps only the selected journal', () {
      final r = filterEntriesByJournal(entries, 'j1');
      expect(r.map((e) => e.entryId), ['1', '3']);
    });

    test('unknown journal yields empty list', () {
      expect(filterEntriesByJournal(entries, 'ghost'), isEmpty);
    });
  });

  group('weekdayCounts', () {
    test('buckets top-level entries by weekday (일=0..토=6)', () {
      final entries = [
        // 2026-06-14 is a Sunday → index 0
        _e(id: '1', at: DateTime(2026, 6, 14)),
        _e(id: '2', at: DateTime(2026, 6, 14)),
        // 2026-06-15 Monday → index 1
        _e(id: '3', at: DateTime(2026, 6, 15)),
        // reply excluded
        _e(id: '4', at: DateTime(2026, 6, 15), replyTo: '3'),
        // other month excluded
        _e(id: '5', at: DateTime(2026, 5, 15)),
      ];
      final r = weekdayCounts(entries, 2026, 6);
      expect(r, [2, 1, 0, 0, 0, 0, 0]);
    });

    test('all zeros when no entries', () {
      expect(weekdayCounts(const [], 2026, 6), [0, 0, 0, 0, 0, 0, 0]);
    });
  });

  group('dominantMoodByDay', () {
    test('picks the most frequent mood per day', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 5), mood: Mood.good),
        _e(id: '2', at: DateTime(2026, 6, 5), mood: Mood.good),
        _e(id: '3', at: DateTime(2026, 6, 5), mood: Mood.hard),
        _e(id: '4', at: DateTime(2026, 6, 6), mood: Mood.hard),
      ];
      final r = dominantMoodByDay(entries, 2026, 6);
      expect(r[5], Mood.good);
      expect(r[6], Mood.hard);
    });

    test('ties resolve to the earlier mood in enum order', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 7), mood: Mood.neutral),
        _e(id: '2', at: DateTime(2026, 6, 7), mood: Mood.good),
      ];
      expect(dominantMoodByDay(entries, 2026, 6)[7], Mood.good);
    });

    test('days without a mood and replies are excluded', () {
      final entries = [
        _e(id: '1', at: DateTime(2026, 6, 8)), // no mood
        _e(id: '2', at: DateTime(2026, 6, 9), mood: Mood.good, replyTo: '1'),
      ];
      expect(dominantMoodByDay(entries, 2026, 6), isEmpty);
    });
  });
}
