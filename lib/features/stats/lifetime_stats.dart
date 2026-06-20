import '../../shared/models/diary_entry.dart';
import 'stats_provider.dart';
import 'streak.dart';

/// A whole-history summary shown on the "내 기록 요약" screen.
class LifetimeStats {
  const LifetimeStats({
    required this.totalEntries,
    required this.totalChars,
    required this.recordedDays,
    required this.longestStreak,
    this.firstDate,
  });

  final int totalEntries; // top-level records only
  final int totalChars; // grapheme-aware sum of bodies
  final int recordedDays; // distinct calendar days with a record
  final int longestStreak; // best consecutive-day run, ever
  final DateTime? firstDate; // earliest top-level record, null when none

  bool get isEmpty => totalEntries == 0;
}

/// Pure: aggregate every [entries] into lifetime totals. 답장(reply) records
/// are excluded so the figures match the timeline.
LifetimeStats computeLifetimeStats(List<DiaryEntry> entries) {
  final tops = entries.where((e) => e.replyToEntryId == null).toList();
  if (tops.isEmpty) {
    return const LifetimeStats(
      totalEntries: 0,
      totalChars: 0,
      recordedDays: 0,
      longestStreak: 0,
    );
  }
  final days = recordedDates(tops);
  final first = tops
      .map((e) => e.createdAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return LifetimeStats(
    totalEntries: tops.length,
    totalChars: totalChars(tops),
    recordedDays: days.length,
    longestStreak: longestStreak(days),
    firstDate: DateTime(first.year, first.month, first.day),
  );
}
