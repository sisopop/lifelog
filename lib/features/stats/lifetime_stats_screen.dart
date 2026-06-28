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
    final journalList = (ref.watch(journalsProvider).asData?.value ?? const [])
        .where((j) => !j.isArchived)
        .toList();
    final journals = journalList.length;
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
                    onTap: () => context.push(
                      Uri(path: '/mood', queryParameters: {'m': domMood.name})
                          .toString(),
                    ),
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
                Builder(builder: (context) {
                  final photos = photoEntryCount(entries);
                  if (photos == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '📷 사진을 남긴 기록이 $photos개예요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = photoEntryShare(entries);
                  if (pct == null || pct == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🖼️ 기록의 $pct%에 사진을 담았어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = taggedEntryShare(entries);
                  if (pct == null || pct == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🏷️ 기록의 $pct%에 태그를 달았어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = locationEntryShare(entries);
                  if (pct == null || pct == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🗺️ 기록의 $pct%에 장소를 남겼어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final favs = favoriteCount(entries);
                  if (favs == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '⭐ 즐겨찾기한 기록이 $favs개예요',
                      onTap: () => context.push('/favorites'),
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = favoriteEntryShare(entries);
                  if (pct == null || pct == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '✨ 기록의 $pct%를 즐겨찾기했어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final busy = busiestJournal(entries);
                  if (busy == null) return const SizedBox.shrink();
                  final j = journalList
                      .where((j) => j.journalId == busy.key)
                      .firstOrNull;
                  if (j == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '📚 가장 많이 쓴 일기장은 ${j.title}이에요 (${busy.value}개)',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final replies = replyCount(entries);
                  if (replies == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '💬 답장을 $replies번 주고받았어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = moodEntryShare(entries);
                  if (pct == null || pct == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '💭 기록의 $pct%에 기분을 남겼어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = positiveMoodShare(entries);
                  if (pct == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '😊 기분을 남긴 기록 중 $pct%가 좋은 기분이었어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = titleEntryShare(entries);
                  if (pct == null || pct == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '📝 기록의 $pct%에 제목을 달았어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = aiSummaryShare(entries);
                  if (pct == null || pct == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🤖 기록의 $pct%에 AI 요약이 있어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final pct = sharedEntryShare(entries);
                  if (pct == null || pct == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🔗 기록의 $pct%를 공유했어요',
                    ),
                  );
                }),
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
                Builder(builder: (context) {
                  final months = distinctMonthsRecorded(entries);
                  if (months < 2) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🗓️ $months개월에 걸쳐 기록했어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final yearly = entriesThisYear(entries, DateTime.now());
                  if (yearly == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '📅 올해 $yearly개 기록했어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final avg = averageEntriesPerMonth(entries);
                  if (avg == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '📊 한 달에 평균 $avg개 기록해요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final maxDay = maxEntriesInOneDay(entries);
                  if (maxDay < 2) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🔥 하루에 가장 많이 쓴 날엔 $maxDay개를 기록했어요',
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
                Builder(builder: (context) {
                  // 단일 장소는 위 "가장 많이 다녀온 곳" 라인과 겹쳐 자명하므로 숨긴다.
                  final places = distinctPlacesVisited(entries);
                  if (places < 2) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🧭 지금까지 $places곳을 다녀왔어요',
                    ),
                  );
                }),
                Builder(builder: (context) {
                  final tag = mostUsedTag(entries);
                  if (tag == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🏷️ 가장 많이 쓴 태그는 #${tag.key} 예요 '
                          '(${tag.value}개)',
                      onTap: () => context.push(
                        Uri(path: '/tag', queryParameters: {'t': tag.key})
                            .toString(),
                      ),
                    ),
                  );
                }),
                Builder(builder: (context) {
                  // 단일 태그는 위 "가장 많이 쓴 태그" 라인과 겹쳐 자명하므로 숨긴다.
                  final kinds = distinctTagsUsed(entries);
                  if (kinds < 2) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _InsightLine(
                      text: '🔖 지금까지 $kinds종류의 태그를 사용했어요',
                    ),
                  );
                }),
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

