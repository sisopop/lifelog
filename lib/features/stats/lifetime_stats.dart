import 'package:characters/characters.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import 'stats_provider.dart';
import 'streak.dart';

// Pure insight helpers (day-part, weekday, gaps, shares, counts, moods, tags,
// monthly trends) live in the part file to keep each file under 500 lines.
part 'lifetime_insights.dart';

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

  /// Average body length per record (graphemes), rounded to the nearest whole
  /// number. 0 when there are no records.
  int get avgCharsPerEntry =>
      totalEntries == 0 ? 0 : (totalChars / totalEntries).round();
}

/// Pure: how many days the journaling habit spans, counting the first day as
/// day 1 (so the day of [firstDate] returns 1). Returns null when [firstDate]
/// is null or lies in the future relative to [now]. Time is ignored.
int? daysSinceFirstEntry(DateTime? firstDate, DateTime now) {
  if (firstDate == null) return null;
  final first = DateTime(firstDate.year, firstDate.month, firstDate.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(first).inDays;
  if (diff < 0) return null;
  return diff + 1;
}

/// Pure: what share of the days since the first record actually have a record,
/// as an integer percent (0..100). [recordedDays] is the count of distinct
/// calendar days with a record; [spanDays] is the inclusive day count since the
/// first entry (i.e. [daysSinceFirstEntry]). Returns null when [spanDays] is
/// null or below 2 (a single-day span has no meaningful ratio). Clamped to 100.
int? recordingConsistency(int recordedDays, int? spanDays) {
  if (spanDays == null || spanDays < 2) return null;
  final pct = (recordedDays / spanDays * 100).round();
  return pct > 100 ? 100 : pct;
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

/// Pure: the average number of top-level records per month the user actually
/// recorded in, rounded to the nearest whole number. Reuses
/// [distinctMonthsRecorded]. Replies are excluded. Returns null when fewer than
/// two distinct months carry a record (a single month's average is just its
/// total, so it is not a meaningful pace).
int? averageEntriesPerMonth(List<DiaryEntry> entries) {
  final tops = entries.where((e) => e.replyToEntryId == null).length;
  final months = distinctMonthsRecorded(entries);
  if (months < 2) return null;
  return (tops / months).round();
}
