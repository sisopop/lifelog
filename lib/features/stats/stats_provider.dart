import 'package:characters/characters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../entries/entries_provider.dart';

/// Async monthly AI report: Gemini if a key is set, else the local narrative.
final monthlyReportProvider = FutureProvider<String>((ref) async {
  final stats = ref.watch(monthlyStatsProvider);
  final entries = ref.watch(reviewEntriesProvider);
  final local = monthlyNarrative(stats, entries);

  final gemini = ref.read(geminiServiceProvider);
  if (!gemini.enabled || stats.isEmpty) return local;

  final moodLine = stats.moodRatio.entries
      .map((e) => '${e.key.label} ${(e.value * 100).round()}%')
      .join(', ');
  final tagLine = stats.topTags.isEmpty
      ? '(없음)'
      : stats.topTags.map((t) => '${t.key}(${t.value})').join(', ');
  final context = '''
- 기간: ${stats.year}년 ${stats.month}월
- 기록한 날: ${stats.daysRecorded}일, 총 기록: ${stats.total}개
- 감정 분포: $moodLine
- 자주 쓴 태그: $tagLine
''';

  final ai = await gemini.monthlyReport(context);
  return (ai != null && ai.isNotEmpty) ? ai : local;
});

/// One day in the weekly strip.
class DayDot {
  const DayDot(this.date, this.label, this.done);
  final DateTime date;
  final String label;
  final bool done;
}

/// Pure: last 7 days (oldest → [now]) with whether a top-level entry exists
/// that day. 답장(reply) records don't count as a day's entry.
List<DayDot> weekDots(List<DiaryEntry> entries, DateTime now) {
  const labels = ['일', '월', '화', '수', '목', '금', '토'];
  final today = DateTime(now.year, now.month, now.day);

  bool hasEntryOn(DateTime d) => entries.any((e) =>
      e.replyToEntryId == null &&
      e.createdAt.year == d.year &&
      e.createdAt.month == d.month &&
      e.createdAt.day == d.day);

  return List.generate(7, (i) {
    final d = today.subtract(Duration(days: 6 - i));
    return DayDot(d, labels[d.weekday % 7], hasEntryOn(d));
  });
}

/// Last 7 days (oldest -> today) with whether an entry exists that day.
final weeklyProgressProvider = Provider<List<DayDot>>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  return weekDots(entries, DateTime.now());
});

/// Pure: number of top-level entries created in [year]/[month].
/// 답장(reply) records are excluded so it matches the timeline.
int monthEntryCount(List<DiaryEntry> entries, int year, int month) {
  var n = 0;
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (e.createdAt.year == year && e.createdAt.month == month) n++;
  }
  return n;
}

/// How many top-level entries the user has recorded in the current month.
final thisMonthCountProvider = Provider<int>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  final now = DateTime.now();
  return monthEntryCount(entries, now.year, now.month);
});

class MonthlyStats {
  const MonthlyStats({
    required this.year,
    required this.month,
    required this.daysRecorded,
    required this.total,
    required this.charsWritten,
    required this.moodRatio,
    required this.topTags,
  });

  final int year;
  final int month;
  final int daysRecorded;
  final int total;
  final int charsWritten; // grapheme-aware sum of all top-level bodies
  final Map<Mood, double> moodRatio; // 0..1 of total
  final List<MapEntry<String, int>> topTags;

  bool get isEmpty => total == 0;
}

/// The (year, month) currently shown on the 회고 screen.
class ReviewMonth {
  const ReviewMonth(this.year, this.month);
  final int year;
  final int month;

  ReviewMonth get previous =>
      month == 1 ? ReviewMonth(year - 1, 12) : ReviewMonth(year, month - 1);
  ReviewMonth get next =>
      month == 12 ? ReviewMonth(year + 1, 1) : ReviewMonth(year, month + 1);

  /// True if this month is at or after [other] (i.e. can't go further forward).
  bool isAtOrAfter(ReviewMonth other) =>
      year > other.year || (year == other.year && month >= other.month);

  @override
  bool operator ==(Object other) =>
      other is ReviewMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

/// Holds the month the user is reviewing; starts at the current month and
/// never advances past it (no future months to review).
class ReviewMonthNotifier extends Notifier<ReviewMonth> {
  @override
  ReviewMonth build() {
    final now = DateTime.now();
    return ReviewMonth(now.year, now.month);
  }

  ReviewMonth get _current {
    final now = DateTime.now();
    return ReviewMonth(now.year, now.month);
  }

  bool get canGoNext => !state.isAtOrAfter(_current);

  void goPrevious() => state = state.previous;
  void goNext() {
    if (canGoNext) state = state.next;
  }
}

final reviewMonthProvider =
    NotifierProvider<ReviewMonthNotifier, ReviewMonth>(ReviewMonthNotifier.new);

/// Pure: keep only entries of [journalId], or all when null (전체).
List<DiaryEntry> filterEntriesByJournal(
    List<DiaryEntry> entries, String? journalId) {
  if (journalId == null) return entries;
  return entries.where((e) => e.journalId == journalId).toList();
}

/// The journal the 회고 screen is scoped to (null = 전체).
class ReviewJournalNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? journalId) => state = journalId;
}

final reviewJournalProvider =
    NotifierProvider<ReviewJournalNotifier, String?>(ReviewJournalNotifier.new);

/// Entries scoped to the selected review journal (drives all 회고 stats).
final reviewEntriesProvider = Provider<List<DiaryEntry>>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  return filterEntriesByJournal(entries, ref.watch(reviewJournalProvider));
});

/// Pure: grapheme-aware sum of the trimmed body length across [entries]
/// (Korean syllables and emoji count as one). Used for the "쓴 글자" stat.
int totalChars(List<DiaryEntry> entries) {
  var sum = 0;
  for (final e in entries) {
    sum += e.content.trim().characters.length;
  }
  return sum;
}

/// Pure aggregation: entries → review stats for the given year/month.
/// Excludes 답장(reply) records so counts/ratios reflect real diary entries.
MonthlyStats computeMonthlyStats(
    List<DiaryEntry> entries, int year, int month) {
  final monthEntries = entries
      .where((e) =>
          e.replyToEntryId == null &&
          e.createdAt.year == year &&
          e.createdAt.month == month)
      .toList();

  final days = monthEntries.map((e) => e.createdAt.day).toSet().length;
  final total = monthEntries.length;
  final charsWritten = totalChars(monthEntries);

  final moodCount = <Mood, int>{};
  for (final e in monthEntries) {
    if (e.mood != null) moodCount[e.mood!] = (moodCount[e.mood] ?? 0) + 1;
  }
  final moodRatio = <Mood, double>{
    for (final m in Mood.values)
      m: total == 0 ? 0 : (moodCount[m] ?? 0) / total,
  };

  final tagCount = <String, int>{};
  for (final e in monthEntries) {
    for (final t in e.tags) {
      tagCount[t] = (tagCount[t] ?? 0) + 1;
    }
  }
  final topTags = tagCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return MonthlyStats(
    year: year,
    month: month,
    daysRecorded: days,
    total: total,
    charsWritten: charsWritten,
    moodRatio: moodRatio,
    topTags: topTags.take(5).toList(),
  );
}

/// Aggregates the selected month's entries into review stats.
final monthlyStatsProvider = Provider<MonthlyStats>((ref) {
  final entries = ref.watch(reviewEntriesProvider);
  final m = ref.watch(reviewMonthProvider);
  return computeMonthlyStats(entries, m.year, m.month);
});

/// Pure: signed change in top-level entry count between [year]/[month] and the
/// immediately preceding calendar month. Positive = more than last month,
/// negative = fewer, 0 = same (or no data either way).
int monthOverMonthDelta(List<DiaryEntry> entries, int year, int month) {
  final prevYear = month == 1 ? year - 1 : year;
  final prevMonth = month == 1 ? 12 : month - 1;
  return monthEntryCount(entries, year, month) -
      monthEntryCount(entries, prevYear, prevMonth);
}

/// Month-over-month change in record count for the selected review month,
/// scoped to the selected journal.
final monthDeltaProvider = Provider<int>((ref) {
  final entries = ref.watch(reviewEntriesProvider);
  final m = ref.watch(reviewMonthProvider);
  return monthOverMonthDelta(entries, m.year, m.month);
});

/// Pure: average gap in days between distinct recorded days *within* the given
/// month (top-level only). Returns null when the month has fewer than two
/// distinct recorded days, since a gap needs two endpoints. 0 means every
/// recorded day was consecutive.
int? monthlyAverageGapDays(List<DiaryEntry> entries, int year, int month) {
  final days = <int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (e.createdAt.year != year || e.createdAt.month != month) continue;
    days.add(e.createdAt.day);
  }
  if (days.length < 2) return null;
  final sorted = days.toList()..sort();
  final span = sorted.last - sorted.first;
  return (span / (sorted.length - 1)).round();
}

/// Average recording gap (days) for the month currently shown on the 회고
/// screen, scoped to the selected journal.
final monthlyGapProvider = Provider<int?>((ref) {
  final entries = ref.watch(reviewEntriesProvider);
  final m = ref.watch(reviewMonthProvider);
  return monthlyAverageGapDays(entries, m.year, m.month);
});

/// Pure: the day (1..31) of the given month with the most top-level records,
/// paired with that count. Returns null when the month has no records. Ties
/// resolve to the earlier day. Only meaningful (count >= 2) is left to callers.
MapEntry<int, int>? busiestDayOfMonth(
    List<DiaryEntry> entries, int year, int month) {
  final counts = <int, int>{};
  for (final e in entries) {
    if (e.replyToEntryId != null) continue;
    if (e.createdAt.year != year || e.createdAt.month != month) continue;
    counts[e.createdAt.day] = (counts[e.createdAt.day] ?? 0) + 1;
  }
  if (counts.isEmpty) return null;
  final days = counts.keys.toList()..sort();
  var best = MapEntry(days.first, counts[days.first]!);
  for (final d in days) {
    if (counts[d]! > best.value) best = MapEntry(d, counts[d]!);
  }
  return best;
}

/// Busiest recording day for the month currently shown on the 회고 screen.
final busiestDayProvider = Provider<MapEntry<int, int>?>((ref) {
  final entries = ref.watch(reviewEntriesProvider);
  final m = ref.watch(reviewMonthProvider);
  return busiestDayOfMonth(entries, m.year, m.month);
});

/// Days (1..31) of the given month that have at least one top-level record.
Set<int> recordedDaysOfMonth(
    List<DiaryEntry> entries, int year, int month) {
  return {
    for (final e in entries)
      if (e.replyToEntryId == null &&
          e.createdAt.year == year &&
          e.createdAt.month == month)
        e.createdAt.day,
  };
}

/// Recorded-day set for the month currently shown on the 회고 screen.
final recordedDaysProvider = Provider<Set<int>>((ref) {
  final entries = ref.watch(reviewEntriesProvider);
  final m = ref.watch(reviewMonthProvider);
  return recordedDaysOfMonth(entries, m.year, m.month);
});

/// Dominant mood per recorded day of the month (ties → earlier Mood in enum
/// order). Days whose records carry no mood are absent from the map.
Map<int, Mood> dominantMoodByDay(
    List<DiaryEntry> entries, int year, int month) {
  final perDay = <int, Map<Mood, int>>{};
  for (final e in entries) {
    if (e.replyToEntryId == null &&
        e.mood != null &&
        e.createdAt.year == year &&
        e.createdAt.month == month) {
      (perDay[e.createdAt.day] ??= {}).update(
        e.mood!,
        (c) => c + 1,
        ifAbsent: () => 1,
      );
    }
  }
  final result = <int, Mood>{};
  perDay.forEach((day, counts) {
    Mood? best;
    var bestCount = 0;
    for (final m in Mood.values) {
      final c = counts[m] ?? 0;
      if (c > bestCount) {
        bestCount = c;
        best = m;
      }
    }
    if (best != null) result[day] = best;
  });
  return result;
}

/// Dominant-mood-per-day for the month currently shown on the 회고 screen.
final dayMoodsProvider = Provider<Map<int, Mood>>((ref) {
  final entries = ref.watch(reviewEntriesProvider);
  final m = ref.watch(reviewMonthProvider);
  return dominantMoodByDay(entries, m.year, m.month);
});

/// Top-level record counts per weekday for the given month.
/// Index 0 = 일요일 … 6 = 토요일 (matches the calendar's column order).
List<int> weekdayCounts(List<DiaryEntry> entries, int year, int month) {
  final counts = List<int>.filled(7, 0);
  for (final e in entries) {
    if (e.replyToEntryId == null &&
        e.createdAt.year == year &&
        e.createdAt.month == month) {
      counts[e.createdAt.weekday % 7]++; // DateTime: Sun=7 → 0, Mon=1 … Sat=6
    }
  }
  return counts;
}

/// Per-weekday counts for the month currently shown on the 회고 screen.
final weekdayCountsProvider = Provider<List<int>>((ref) {
  final entries = ref.watch(reviewEntriesProvider);
  final m = ref.watch(reviewMonthProvider);
  return weekdayCounts(entries, m.year, m.month);
});

/// Used by the review AI report card.
String monthlyNarrative(MonthlyStats s, List<DiaryEntry> _) {
  if (s.isEmpty) return '${s.month}월에는 남긴 기록이 없어요.';
  final topTag = s.topTags.isNotEmpty ? s.topTags.first.key : null;
  final dominant = s.moodRatio.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
  final moodWord = switch (dominant) {
    Mood.good => '대체로 좋은 기분',
    Mood.neutral => '잔잔한 기분',
    Mood.hard => '다소 힘든 기분',
  };
  final tagPart = topTag != null ? ' 특히 "$topTag" 관련 기록이 자주 등장했어요.' : '';
  return '이번 달은 $moodWord의 날이 많았어요.$tagPart';
}
