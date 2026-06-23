import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/month_calendar.dart' show moodColor;
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../places/place_directory.dart';
import 'lifetime_share.dart';
import 'lifetime_stats.dart';

part 'lifetime_stats_widgets.dart';

/// "내 기록 요약" — a whole-history snapshot reached from settings.
class LifetimeStatsScreen extends ConsumerWidget {
  const LifetimeStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final journals = (ref.watch(journalsProvider).asData?.value ?? const [])
        .where((j) => !j.isArchived)
        .length;
    final s = computeLifetimeStats(entries);
    final moods = moodBreakdown(entries);
    final domMood = dominantMood(entries);
    final dayParts = dayPartBreakdown(entries);
    final busiest = busiestDayPart(entries);
    final busyDay = busiestWeekday(entries);
    final tags = topTags(entries);
    final trend = recentMonthlyCounts(entries, DateTime.now());
    final longest = longestEntry(entries);
    final first = firstEntry(entries);
    final avgGap = averageEntryGapDays(entries);
    final longestGap = longestGapDays(entries);
    final sinceFirst = daysSinceFirstEntry(s.firstDate, DateTime.now());
    final topPlace = placeCountsSorted(entries).firstOrNull;
    final activeMonth = mostActiveMonth(entries);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 기록 요약',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (!s.isEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: '요약 공유',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(
                    ClipboardData(text: lifetimeStatsShareText(s)));
                messenger.showSnackBar(
                  const SnackBar(content: Text('기록 요약을 복사했어요')),
                );
              },
            ),
        ],
      ),
      body: s.isEmpty
          ? const Center(
              child: Text('아직 기록이 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            icon: Icons.edit_note,
                            label: '총 기록',
                            value: '${s.totalEntries}개')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Stat(
                            icon: Icons.menu_book,
                            label: '일기장',
                            value: '$journals개')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            icon: Icons.text_fields,
                            label: '쓴 글자',
                            value: '${s.totalChars}자')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Stat(
                            icon: Icons.event_available,
                            label: '기록한 날',
                            value: '${s.recordedDays}일')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            icon: Icons.local_fire_department,
                            label: '최장 연속',
                            value: '${s.longestStreak}일')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Stat(
                            icon: Icons.flag,
                            label: '첫 기록',
                            value: s.firstDate == null
                                ? '-'
                                : DateFormat('yyyy.M.d', locale)
                                    .format(s.firstDate!))),
                  ],
                ),
                if (moods.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _MoodDistribution(counts: moods),
                ],
                if (domMood != null) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: '${domMood.emoji} 주로 ${domMood.label} 기분을 기록했어요',
                  ),
                ],
                if (dayParts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DayPartDistribution(counts: dayParts),
                ],
                if (busiest != null) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: '${busiest.key.emoji} 주로 '
                        '${busiest.key.label}에 기록해요 (${busiest.value}개)',
                  ),
                ],
                if (busyDay != null) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: '📅 주로 ${busyDay.key}에 기록해요 (${busyDay.value}개)',
                  ),
                ],
                Builder(builder: (context) {
                  final weekendPct = weekendRecordShare(entries);
                  if (weekendPct == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: weekendPct >= 50
                          ? '🏖️ 기록의 $weekendPct%를 주말에 남겼어요'
                          : '💼 기록의 ${100 - weekendPct}%를 평일에 남겼어요',
                    ),
                  );
                }),
                if (s.avgCharsPerEntry > 0) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: '✍️ 한 번에 평균 ${s.avgCharsPerEntry}자씩 기록해요',
                  ),
                ],
                if (avgGap != null) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: avgGap == 0
                        ? '🗓️ 거의 매일 기록해요'
                        : '🗓️ 평균 $avgGap일마다 기록해요',
                  ),
                ],
                if (longestGap != null && longestGap >= 2) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: '💤 가장 길게 쉰 적은 $longestGap일이에요',
                  ),
                ],
                if (sinceFirst != null) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: '🌱 기록을 시작한 지 $sinceFirst일째예요',
                  ),
                ],
                Builder(builder: (context) {
                  final pct =
                      recordingConsistency(s.recordedDays, sinceFirst);
                  if (pct == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '📆 시작한 뒤 $sinceFirst일 중 ${s.recordedDays}일 '
                          '기록했어요 ($pct%)',
                    ),
                  );
                }),
                if (topPlace != null) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: '📍 가장 많이 다녀온 곳은 ${topPlace.key}예요 '
                        '(${topPlace.value}개)',
                    onTap: () => context.push(
                      Uri(path: '/place', queryParameters: {'l': topPlace.key})
                          .toString(),
                    ),
                  ),
                ],
                if (activeMonth != null && activeMonth.count >= 2) ...[
                  const SizedBox(height: 12),
                  _InsightLine(
                    text: '📈 ${activeMonth.year}년 ${activeMonth.month}월에 '
                        '가장 많이 기록했어요 (${activeMonth.count}개)',
                  ),
                ],
                if (longest != null) ...[
                  const SizedBox(height: 12),
                  _LongestEntryCard(
                    entry: longest,
                    chars: longest.content.trim().characters.length,
                    locale: locale,
                  ),
                ],
                if (first != null) ...[
                  const SizedBox(height: 12),
                  _FirstEntryCard(entry: first, locale: locale),
                ],
                if (trend.any((m) => m.count > 0)) ...[
                  const SizedBox(height: 24),
                  _MonthlyTrend(months: trend),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _TagCloud(tags: tags),
                ],
              ],
            ),
    );
  }
}

