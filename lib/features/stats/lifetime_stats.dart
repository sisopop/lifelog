import 'package:characters/characters.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
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

/// Rough time-of-day buckets used for the "주로 기록하는 시간대" insight.
enum DayPart {
  dawn('새벽', '🌙'), // 00:00–05:59
  morning('아침', '🌅'), // 06:00–11:59
  afternoon('오후', '☀️'), // 12:00–17:59
  evening('저녁', '🌆'); // 18:00–23:59

  const DayPart(this.label, this.emoji);
  final String label;
  final String emoji;
}

DayPart _partOfHour(int hour) {
  if (hour < 6) return DayPart.dawn;
  if (hour < 12) return DayPart.morning;
  if (hour < 18) return DayPart.afternoon;
  return DayPart.evening;
}

/// Pure: the day-part the user records in most often, with its count. Returns
/// null when there are no top-level entries. Ties resolve to the earlier part.
MapEntry<DayPart, int>? busiestDayPart(List<DiaryEntry> entries) {
  final counts = <DayPart, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final p = _partOfHour(e.createdAt.hour);
    counts[p] = (counts[p] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  MapEntry<DayPart, int>? best;
  for (final p in DayPart.values) {
    final c = counts[p];
    if (c != null && (best == null || c > best.value)) {
      best = MapEntry(p, c);
    }
  }
  return best;
}

/// Pure: the busiest day-part within the given [year]/[month], reusing
/// [busiestDayPart]. Returns null when that month has no top-level record.
MapEntry<DayPart, int>? busiestDayPartOfMonth(
    List<DiaryEntry> entries, int year, int month) {
  final monthly = entries
      .where((e) => e.createdAt.year == year && e.createdAt.month == month)
      .toList();
  return busiestDayPart(monthly);
}

/// Pure: count top-level entries by day-part (시간대). Only day-parts that
/// actually occur are present in the map, ordered by [DayPart.values] for
/// stable rendering. Replies are ignored.
Map<DayPart, int> dayPartBreakdown(List<DiaryEntry> entries) {
  final counts = <DayPart, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final p = _partOfHour(e.createdAt.hour);
    counts[p] = (counts[p] ?? 0) + 1;
  }
  return {
    for (final p in DayPart.values)
      if (counts[p] != null) p: counts[p]!,
  };
}

/// Pure: [dayPartBreakdown] restricted to the given [year]/[month]. Returns an
/// empty map when that month has no top-level record.
Map<DayPart, int> dayPartBreakdownOfMonth(
    List<DiaryEntry> entries, int year, int month) {
  final monthly = entries
      .where((e) => e.createdAt.year == year && e.createdAt.month == month)
      .toList();
  return dayPartBreakdown(monthly);
}

/// Korean weekday names indexed by [DateTime.weekday] (1=Mon … 7=Sun).
const _weekdayNames = ['', '월', '화', '수', '목', '금', '토', '일'];

/// Pure: the weekday the user records on most often, as `(name, count)`.
/// Returns null when there are no top-level entries. Ties resolve to the
/// earlier weekday (Mon before Sun).
MapEntry<String, int>? busiestWeekday(List<DiaryEntry> entries) {
  final counts = <int, int>{}; // weekday(1..7) -> count
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final w = e.createdAt.weekday;
    counts[w] = (counts[w] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  int? bestDay;
  var bestCount = 0;
  for (var w = 1; w <= 7; w++) {
    final c = counts[w];
    if (c != null && c > bestCount) {
      bestDay = w;
      bestCount = c;
    }
  }
  return MapEntry('${_weekdayNames[bestDay!]}요일', bestCount);
}

/// Pure: the average number of days between consecutive recorded calendar days
/// across top-level entries. Returns null when fewer than two distinct days
/// were recorded (no meaningful interval). Replies are ignored.
int? averageEntryGapDays(List<DiaryEntry> entries) {
  final days = <DateTime>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    days.add(DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day));
  }
  if (days.length < 2) return null;
  final sorted = days.toList()..sort();
  final span = sorted.last.difference(sorted.first).inDays;
  return (span / (sorted.length - 1)).round();
}

/// Pure: the longest gap, in days, between two consecutive recorded calendar
/// days across top-level entries. Returns null when fewer than two distinct
/// days were recorded. A gap of 1 means recorded on back-to-back days, so the
/// value is always >= 1 when non-null. Replies are ignored.
int? longestGapDays(List<DiaryEntry> entries) {
  final days = <DateTime>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    days.add(DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day));
  }
  if (days.length < 2) return null;
  final sorted = days.toList()..sort();
  var longest = 0;
  for (var i = 1; i < sorted.length; i++) {
    final gap = sorted[i].difference(sorted[i - 1]).inDays;
    if (gap > longest) longest = gap;
  }
  return longest;
}

/// Pure: what share of the month's days carry a record, as a 0–100 percent.
/// For the current month the denominator is the number of days elapsed so far
/// ([now.day]); for past months it is the full month length. Returns null when
/// nothing was recorded or the denominator is non-positive.
int? monthlyRecordingRate(
    int recordedDays, int year, int month, DateTime now) {
  if (recordedDays <= 0) return null;
  final isCurrent = now.year == year && now.month == month;
  final denom = isCurrent ? now.day : DateTime(year, month + 1, 0).day;
  if (denom <= 0) return null;
  return (recordedDays / denom * 100).round().clamp(0, 100);
}

/// Pure: the longest gap (in days) between consecutive recorded days *within*
/// the given [year]/[month]. Reuses [longestGapDays] on that month's entries,
/// so it is null when fewer than two distinct days were recorded that month.
int? longestGapDaysOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where((e) =>
      e.createdAt.year == year && e.createdAt.month == month);
  return longestGapDays(monthly.toList());
}

/// Pure: the top-level entry with the longest (grapheme-aware, trimmed) body.
/// Returns null when no top-level entry carries any text. Ties resolve to the
/// most recent entry.
DiaryEntry? longestEntry(List<DiaryEntry> entries) {
  DiaryEntry? best;
  var bestLen = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final len = e.content.trim().characters.length;
    if (len == 0) continue;
    if (len > bestLen ||
        (len == bestLen && best != null && e.createdAt.isAfter(best.createdAt))) {
      bestLen = len;
      best = e;
    }
  }
  return best;
}

/// Pure: what percent of top-level records were written on a weekend (Saturday
/// or Sunday), as a 0–100 value. Replies are excluded. Returns null when there
/// are no top-level records.
int? weekendRecordShare(List<DiaryEntry> entries) {
  var total = 0;
  var weekend = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    total++;
    final wd = e.createdAt.weekday;
    if (wd == DateTime.saturday || wd == DateTime.sunday) weekend++;
  }
  if (total == 0) return null;
  return (weekend * 100 / total).round();
}

/// Pure: the weekend record share (0–100) for one calendar month. Filters to
/// the given year/month, then reuses [weekendRecordShare]. Returns null when
/// that month has no top-level records.
int? weekendRecordShareOfMonth(
    List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return weekendRecordShare(monthly.toList());
}

/// Pure: how many distinct calendar months contain at least one top-level
/// record (replies excluded). Returns 0 when there are none.
int distinctMonthsRecorded(List<DiaryEntry> entries) {
  final months = <String>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    months.add('${e.createdAt.year}-${e.createdAt.month}');
  }
  return months.length;
}

/// Pure: the earliest top-level record (replies excluded). Returns null when
/// there is no top-level entry. Ties (same instant) keep the first encountered.
DiaryEntry? firstEntry(List<DiaryEntry> entries) {
  DiaryEntry? best;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (best == null || e.createdAt.isBefore(best.createdAt)) best = e;
  }
  return best;
}

/// Pure: the longest (grapheme-aware, trimmed) top-level record within the
/// given [year]/[month]. Returns null when that month has no record with text.
DiaryEntry? longestEntryOfMonth(
    List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where((e) =>
      e.createdAt.year == year && e.createdAt.month == month);
  return longestEntry(monthly.toList());
}

/// Pure: how many top-level records in the given [year]/[month] are starred
/// (favorite). Replies are excluded. Returns 0 when none.
int favoriteCountOfMonth(List<DiaryEntry> entries, int year, int month) {
  var count = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null || !e.isFavorite) continue;
    if (e.createdAt.year != year || e.createdAt.month != month) continue;
    count++;
  }
  return count;
}

/// Pure: how many top-level records carry at least one photo (a non-empty
/// [DiaryEntry.mediaUrls]). Replies are excluded. Returns 0 when none.
int photoEntryCount(List<DiaryEntry> entries) {
  var count = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (e.mediaUrls.isEmpty) continue;
    count++;
  }
  return count;
}

/// Pure: what share of top-level records carry at least one tag, as a 0–100
/// percent. Replies are excluded. Returns null when there are no top-level
/// records.
int? taggedEntryShare(List<DiaryEntry> entries) {
  var total = 0;
  var tagged = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    total++;
    if (e.tags.isNotEmpty) tagged++;
  }
  if (total == 0) return null;
  return (tagged * 100 / total).round();
}

/// Pure: the tagged-record share (0–100) for one calendar month. Filters to the
/// given [year]/[month], then reuses [taggedEntryShare]. Returns null when that
/// month has no top-level records.
int? taggedEntryShareOfMonth(List<DiaryEntry> entries, int year, int month) {
  final monthly = entries.where(
      (e) => e.createdAt.year == year && e.createdAt.month == month);
  return taggedEntryShare(monthly.toList());
}

/// Pure: count top-level entries by mood. Only moods that actually occur are
/// present in the map; entries without a mood are ignored. Ordered by
/// [Mood.values] for stable rendering.
Map<Mood, int> moodBreakdown(List<DiaryEntry> entries) {
  final counts = <Mood, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final m = e.mood;
    if (m == null) continue;
    counts[m] = (counts[m] ?? 0) + 1;
  }
  return {
    for (final m in Mood.values)
      if (counts[m] != null) m: counts[m]!,
  };
}

/// Pure: the most-recorded mood across top-level entries, reusing
/// [moodBreakdown]. Returns null when no top-level entry carries a mood. Ties
/// resolve to the earlier [Mood.values] entry.
Mood? dominantMood(List<DiaryEntry> entries) {
  final counts = moodBreakdown(entries);
  Mood? best;
  var bestCount = 0;
  for (final m in Mood.values) {
    final c = counts[m] ?? 0;
    if (c > bestCount) {
      bestCount = c;
      best = m;
    }
  }
  return best;
}

/// Pure: most-used tags across top-level entries, most-frequent first.
/// Ties resolve alphabetically. Capped at [limit] (no cap when limit <= 0).
List<MapEntry<String, int>> topTags(List<DiaryEntry> entries, {int limit = 12}) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    for (final t in e.tags) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  if (limit > 0 && sorted.length > limit) {
    return sorted.sublist(0, limit);
  }
  return sorted;
}

/// One month's record count, used by the recent-months trend chart.
class MonthCount {
  const MonthCount(this.year, this.month, this.count);
  final int year;
  final int month;
  final int count;
}

/// Pure: top-level record counts for the last [months] calendar months ending
/// with [now]'s month, oldest first. Months with no records show a zero count
/// so the trend chart keeps an even spacing.
List<MonthCount> recentMonthlyCounts(
  List<DiaryEntry> entries,
  DateTime now, {
  int months = 6,
}) {
  if (months <= 0) return const [];
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    counts['${e.createdAt.year}-${e.createdAt.month}'] =
        (counts['${e.createdAt.year}-${e.createdAt.month}'] ?? 0) + 1;
  }
  final result = <MonthCount>[];
  for (var i = months - 1; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    result.add(MonthCount(m.year, m.month, counts['${m.year}-${m.month}'] ?? 0));
  }
  return result;
}

/// Pure: the calendar month with the most top-level records across all of
/// [entries], as a [MonthCount]. Returns null when there are no records.
/// Ties resolve to the earlier month.
MonthCount? mostActiveMonth(List<DiaryEntry> entries) {
  final counts = <String, int>{}; // "y-m" -> count
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    final key = '${e.createdAt.year}-${e.createdAt.month}';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  int? bestYear;
  int? bestMonth;
  var bestCount = 0;
  counts.forEach((key, count) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final isEarlier = bestYear == null ||
        y < bestYear! ||
        (y == bestYear! && m < bestMonth!);
    if (count > bestCount || (count == bestCount && isEarlier)) {
      bestCount = count;
      bestYear = y;
      bestMonth = m;
    }
  });
  return MonthCount(bestYear!, bestMonth!, bestCount);
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
