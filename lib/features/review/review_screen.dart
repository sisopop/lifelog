import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../entries/entries_provider.dart';
import '../stats/stats_provider.dart';

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
          ),
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
                  .map((t) => Chip(label: Text('#${t.key} ${t.value}')))
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

/// A compact month grid (일~토) highlighting days that have a record.
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.year,
    required this.month,
    required this.recordedDays,
  });
  final int year;
  final int month;
  final Set<int> recordedDays;

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
      for (var d = 1; d <= daysInMonth; d++) _DayCell(d, recordedDays.contains(d)),
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
  const _DayCell(this.day, this.recorded);
  final int day;
  final bool recorded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: recorded ? AppColors.primary : AppColors.background,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 12,
          fontWeight: recorded ? FontWeight.w700 : FontWeight.w500,
          color: recorded ? Colors.white : AppColors.textSecondary,
        ),
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
