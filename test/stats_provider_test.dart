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
}
