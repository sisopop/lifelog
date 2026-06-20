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
