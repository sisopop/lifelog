import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/month_calendar.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../stats/stats_provider.dart';
import '../stats/streak.dart';

part 'review_widgets.dart';

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
          Builder(builder: (context) {
            final recordedDays = ref.watch(recordedDaysProvider);
            return MonthCalendar(
              year: stats.year,
              month: stats.month,
              recordedDays: recordedDays,
              dayMoods: ref.watch(dayMoodsProvider),
              onDayTap: (day) {
                if (!recordedDays.contains(day)) return;
                final d = DateTime(stats.year, stats.month, day);
                final iso =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                context.push('/day/$iso');
              },
            );
          }),
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
