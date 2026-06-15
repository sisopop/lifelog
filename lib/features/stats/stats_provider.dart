import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../entries/entries_provider.dart';

/// Async monthly AI report: Gemini if a key is set, else the local narrative.
final monthlyReportProvider = FutureProvider<String>((ref) async {
  final stats = ref.watch(monthlyStatsProvider);
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
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
  const DayDot(this.label, this.done);
  final String label;
  final bool done;
}

/// Last 7 days (oldest -> today) with whether an entry exists that day.
final weeklyProgressProvider = Provider<List<DayDot>>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  const labels = ['일', '월', '화', '수', '목', '금', '토'];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  bool hasEntryOn(DateTime d) => entries.any((e) =>
      e.createdAt.year == d.year &&
      e.createdAt.month == d.month &&
      e.createdAt.day == d.day);

  return List.generate(7, (i) {
    final d = today.subtract(Duration(days: 6 - i));
    return DayDot(labels[d.weekday % 7], hasEntryOn(d));
  });
});

class MonthlyStats {
  const MonthlyStats({
    required this.year,
    required this.month,
    required this.daysRecorded,
    required this.total,
    required this.moodRatio,
    required this.topTags,
  });

  final int year;
  final int month;
  final int daysRecorded;
  final int total;
  final Map<Mood, double> moodRatio; // 0..1 of total
  final List<MapEntry<String, int>> topTags;

  bool get isEmpty => total == 0;
}

/// Aggregates the current month's entries into review stats.
final monthlyStatsProvider = Provider<MonthlyStats>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  final now = DateTime.now();
  final monthEntries = entries
      .where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month)
      .toList();

  final days = monthEntries.map((e) => e.createdAt.day).toSet().length;
  final total = monthEntries.length;

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
    year: now.year,
    month: now.month,
    daysRecorded: days,
    total: total,
    moodRatio: moodRatio,
    topTags: topTags.take(5).toList(),
  );
});

/// Used by the review AI report card.
String monthlyNarrative(MonthlyStats s, List<DiaryEntry> _) {
  if (s.isEmpty) return '아직 이번 달 기록이 없어요. 오늘 첫 기록을 남겨보세요.';
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
