import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../stats/stats_provider.dart';
import '../stats/streak.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthlyStatsProvider);
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final report = ref.watch(monthlyReportProvider);
    final monthCtrl = ref.read(reviewMonthProvider.notifier);
    final canGoNext = monthCtrl.canGoNext;
    return Scaffold(
      appBar: AppBar(title: const Text('회고', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _JournalFilterRow(),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: '이전 달',
                onPressed: monthCtrl.goPrevious,
              ),
              Expanded(
                child: Text('${stats.year}년 ${stats.month}월',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: '다음 달',
                color: canGoNext ? null : AppColors.textHint.withValues(alpha: 0.4),
                onPressed: canGoNext ? monthCtrl.goNext : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StreakBanner(ref.watch(streakProvider)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatBox(label: '기록한 날', value: '${stats.daysRecorded}일')),
              const SizedBox(width: 12),
              Expanded(child: _StatBox(label: '총 기록', value: '${stats.total}개')),
            ],
          ),
          const SizedBox(height: 20),
          const Text('기록 달력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _MonthCalendar(
            year: stats.year,
            month: stats.month,
            recordedDays: ref.watch(recordedDaysProvider),
            dayMoods: ref.watch(dayMoodsProvider),
          ),
          const SizedBox(height: 10),
          const _MoodLegend(),
          const SizedBox(height: 20),
          const Text('요일별 기록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _WeekdayChart(ref.watch(weekdayCountsProvider)),
          const SizedBox(height: 20),
          const Text('감정 분포', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final m in Mood.values) _MoodBar(m, stats.moodRatio[m] ?? 0),
          if (stats.topTags.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('자주 쓴 태그', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: stats.topTags
                  .map((t) => ActionChip(
                        label: Text('#${t.key} ${t.value}'),
                        onPressed: () => context.push(
                            Uri(path: '/tag', queryParameters: {'t': t.key})
                                .toString()),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryDark),
                  SizedBox(width: 6),
                  Text('AI 요약 리포트',
                      style: TextStyle(
                          color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),
                Text(
                  report.when(
                    data: (t) => t,
                    loading: () => monthlyNarrative(stats, entries),
                    error: (_, _) => monthlyNarrative(stats, entries),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal chip row scoping all 회고 stats to 전체 or one journal.
class _JournalFilterRow extends ConsumerWidget {
  const _JournalFilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journals = (ref.watch(journalsProvider).asData?.value ?? const [])
        .where((j) => !j.isArchived)
        .toList();
    if (journals.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(reviewJournalProvider);
    final ctrl = ref.read(reviewJournalProvider.notifier);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: '전체',
            selected: selected == null,
            onTap: () => ctrl.select(null),
          ),
          for (final j in journals)
            _FilterChip(
              label: '${j.displayIcon} ${j.title}',
              selected: selected == j.journalId,
              onTap: () => ctrl.select(j.journalId),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.primarySoft,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// History-wide streak banner (current run + best run).
class _StreakBanner extends StatelessWidget {
  const _StreakBanner(this.streak);
  final StreakInfo streak;

  @override
  Widget build(BuildContext context) {
    final cur = streak.current;
    final headline =
        cur > 0 ? '🔥 $cur일 연속 기록 중!' : '오늘 기록하고 연속 기록을 시작해보세요';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('최장 연속 기록 ${streak.longest}일',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Maps a mood to its calendar/legend color.
Color moodColor(Mood m) => switch (m) {
      Mood.good => AppColors.moodGood,
      Mood.neutral => AppColors.moodNeutral,
      Mood.hard => AppColors.moodHard,
    };

/// A compact month grid (일~토) highlighting days that have a record,
/// colored by that day's dominant mood (falls back to primary when no mood).
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.year,
    required this.month,
    required this.recordedDays,
    required this.dayMoods,
  });
  final int year;
  final int month;
  final Set<int> recordedDays;
  final Map<int, Mood> dayMoods;

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Sunday-first: leading blanks before day 1.
    final leading = DateTime(year, month, 1).weekday % 7;
    final cells = <Widget>[
      for (final w in _weekdayLabels)
        Center(
          child: Text(w,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
          d,
          recordedDays.contains(d),
          mood: dayMoods[d],
          onTap: recordedDays.contains(d)
              ? () => context.push(
                  '/day/$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}')
              : null,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: cells,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell(this.day, this.recorded, {this.mood, this.onTap});
  final int day;
  final bool recorded;
  final Mood? mood;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Mood color when known (pastel → dark text), else primary, else plain.
    final Color bg = !recorded
        ? AppColors.background
        : (mood != null ? moodColor(mood!) : AppColors.primary);
    final Color fg = !recorded
        ? AppColors.textSecondary
        : (mood != null ? AppColors.textPrimary : Colors.white);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 12,
            fontWeight: recorded ? FontWeight.w700 : FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Small legend explaining the calendar's mood colors.
class _MoodLegend extends StatelessWidget {
  const _MoodLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final m in Mood.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: moodColor(m), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(m.label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
      ],
    );
  }
}

/// Vertical bar chart of top-level record counts per weekday (일~토).
class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart(this.counts);
  final List<int> counts;

  static const _labels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final max = counts.fold<int>(0, (m, c) => c > m ? c : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(counts[i] > 0 ? '${counts[i]}' : '',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Container(
                    height: 80 * (max == 0 ? 0 : counts[i] / max),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: counts[i] > 0
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(minHeight: 4),
                  ),
                  const SizedBox(height: 6),
                  Text(_labels[i],
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  const _MoodBar(this.mood, this.ratio);
  final Mood mood;
  final double ratio;

  Color get _color => switch (mood) {
        Mood.good => AppColors.moodGood,
        Mood.neutral => AppColors.moodNeutral,
        Mood.hard => AppColors.moodHard,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('${mood.emoji} ${mood.label}', style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(_color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${(ratio * 100).round()}%', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
