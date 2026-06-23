import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/month_calendar.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../export/export_markdown.dart';
import '../stats/lifetime_stats.dart';
import '../stats/stats_provider.dart';
import '../stats/streak.dart';
import 'review_share.dart';

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
      appBar: AppBar(
        title: const Text('회고', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (!stats.isEmpty) ...[
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: '이번 달 회고 공유',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(
                    ClipboardData(text: monthlyReviewShareText(stats)));
                messenger.showSnackBar(
                  const SnackBar(content: Text('이번 달 회고를 복사했어요')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: '이번 달 기록 전체 내보내기',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final journals =
                    ref.read(journalsProvider).asData?.value ?? const [];
                final monthEntries = ref.read(reviewEntriesProvider);
                final count = monthEntries
                    .where((e) =>
                        e.createdAt.year == stats.year &&
                        e.createdAt.month == stats.month)
                    .length;
                final text = exportMonthMarkdown(
                    journals, monthEntries, stats.year, stats.month,
                    DateTime.now());
                await Clipboard.setData(ClipboardData(text: text));
                messenger.showSnackBar(
                  SnackBar(
                      content: Text(
                          '${stats.month}월 기록 $count개를 클립보드에 복사했어요')),
                );
              },
            ),
          ],
        ],
      ),
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
              const SizedBox(width: 12),
              Expanded(
                  child: _StatBox(
                      label: '쓴 글자', value: '${stats.charsWritten}자')),
            ],
          ),
          if (!stats.isEmpty) ...[
            const SizedBox(height: 12),
            _DeltaLine(ref.watch(monthDeltaProvider)),
            Builder(builder: (context) {
              final gap = ref.watch(monthlyGapProvider);
              if (gap == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  gap == 0 ? '🗓️ 이번 달은 거의 매일 기록했어요' : '🗓️ 평균 $gap일마다 기록했어요',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              );
            }),
            Builder(builder: (context) {
              final longestGap = longestGapDaysOfMonth(
                  ref.watch(reviewEntriesProvider), stats.year, stats.month);
              if (longestGap == null || longestGap < 2) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '💤 이번 달 가장 길게 쉰 적은 $longestGap일이에요',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              );
            }),
            Builder(builder: (context) {
              final rate = monthlyRecordingRate(
                  stats.daysRecorded, stats.year, stats.month, DateTime.now());
              if (rate == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '📆 ${stats.month}월 중 ${stats.daysRecorded}일 기록했어요 ($rate%)',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              );
            }),
            Builder(builder: (context) {
              final mood = dominantMonthMood(
                  ref.watch(reviewEntriesProvider), stats.year, stats.month);
              if (mood == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${mood.emoji} 이번 달은 주로 ${mood.label} 기분이었어요',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              );
            }),
            Builder(builder: (context) {
              final busiest = ref.watch(busiestDayProvider);
              if (busiest == null || busiest.value < 2) {
                return const SizedBox.shrink();
              }
              final d = DateTime(stats.year, stats.month, busiest.key);
              final iso =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              return _TappableInsight(
                text: '🔥 ${busiest.key}일에 가장 많이 기록했어요 (${busiest.value}개)',
                onTap: () => context.push('/day/$iso'),
              );
            }),
            Builder(builder: (context) {
              final part = busiestDayPartOfMonth(
                  ref.watch(reviewEntriesProvider), stats.year, stats.month);
              if (part == null || part.value < 2) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${part.key.emoji} 이번 달은 주로 ${part.key.label}에 기록했어요 '
                  '(${part.value}개)',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              );
            }),
            Builder(builder: (context) {
              final place = ref.watch(topPlaceProvider);
              if (place == null) return const SizedBox.shrink();
              return _TappableInsight(
                text:
                    '📍 이번 달은 ${place.key}에 가장 많이 다녀왔어요 (${place.value}개)',
                onTap: () => context.push(
                  Uri(path: '/place', queryParameters: {'l': place.key})
                      .toString(),
                ),
              );
            }),
            Builder(builder: (context) {
              final tag = ref.watch(topTagProvider);
              if (tag == null) return const SizedBox.shrink();
              return _TappableInsight(
                text: '🏷️ 이번 달 가장 많이 쓴 태그는 #${tag.key} 예요 (${tag.value}개)',
                onTap: () => context.push(
                  Uri(path: '/tag', queryParameters: {'t': tag.key}).toString(),
                ),
              );
            }),
            Builder(builder: (context) {
              final weekday = ref.watch(busiestWeekdayProvider);
              if (weekday == null || weekday.value < 2) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '📅 이번 달은 주로 ${weekday.key}에 기록했어요 (${weekday.value}개)',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              );
            }),
            if (stats.avgChars > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '✍️ 한 번에 평균 ${stats.avgChars}자씩 썼어요',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            Builder(builder: (context) {
              final favs = favoriteCountOfMonth(
                  ref.watch(reviewEntriesProvider), stats.year, stats.month);
              if (favs == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '⭐ 이번 달 즐겨찾기한 기록이 $favs개 있어요',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              );
            }),
            Builder(builder: (context) {
              final longest = longestEntryOfMonth(
                  ref.watch(reviewEntriesProvider), stats.year, stats.month);
              if (longest == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _MonthLongestCard(
                  entry: longest,
                  chars: longest.content.trim().characters.length,
                ),
              );
            }),
          ],
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
          Builder(builder: (context) {
            final parts = dayPartBreakdownOfMonth(
                ref.watch(reviewEntriesProvider), stats.year, stats.month);
            if (parts.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text('시간대 분포',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _DayPartChart(parts),
              ],
            );
          }),
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
