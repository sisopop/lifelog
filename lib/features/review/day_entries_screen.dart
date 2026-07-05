import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../timeline/timeline_filter.dart';
import 'day_entries.dart';

/// Lists the records of a single day (reached by tapping a day on the
/// 회고 calendar). Each card opens the entry detail.
class DayEntriesScreen extends ConsumerWidget {
  const DayEntriesScreen({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = DateFormat.yMMMMd(locale).format(day);
    final all = ref.watch(entriesProvider).asData?.value ?? const [];
    final entries = entriesOfDay(all, day);
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journalMap = {for (final j in journals) j.journalId: j};
    final replyCounts = replyCountsByParent(all);
    final adjacent = adjacentRecordedDays(all, day);

    String iso(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: '이 날 공유',
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: dayShareText(entries, title)));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이 날의 기록을 복사했어요')),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: '이전 기록일',
            onPressed: adjacent.previous == null
                ? null
                : () => context.pushReplacement('/day/${iso(adjacent.previous!)}'),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: '다음 기록일',
            onPressed: adjacent.next == null
                ? null
                : () => context.pushReplacement('/day/${iso(adjacent.next!)}'),
          ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('이 날의 기록이 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i == 0) {
                  final mood = dominantMoodOf(entries);
                  final chars = totalContentChars(entries);
                  final span = dayTimeSpan(entries);
                  final hm = DateFormat.Hm(locale);
                  final header = [
                    '이 날의 기록 ${entries.length}개',
                    if (mood != null) mood.emoji,
                    if (chars > 0) '총 $chars자',
                    if (span != null)
                      span.first == span.last
                          ? '🕘 ${hm.format(span.first)}'
                          : '🕘 ${hm.format(span.first)}–${hm.format(span.last)}',
                  ].join(' · ');
                  final tags = tagsOfDay(entries);
                  final places = placesOfDay(entries);
                  final avgChars = averageCharsOfDay(entries);
                  final favorites = favoriteCountOfDay(entries);
                  final decorated = decoratedCountOfDay(entries);
                  final photos = photoCountOfDay(entries);
                  final journalNames = journalIdsOfDay(entries)
                      .map((id) => journalMap[id]?.title)
                      .whereType<String>()
                      .toList();
                  final longest = longestEntryOfDay(entries);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(header,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        if (places.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('📍 ${places.take(4).join(' · ')}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('🏷 ${tags.take(6).map((t) => '#$t').join(' ')}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (entries.length >= 2 && avgChars > 0) ...[
                          const SizedBox(height: 4),
                          Text('✍️ 평균 $avgChars자',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (favorites > 0) ...[
                          const SizedBox(height: 4),
                          Text('⭐ 즐겨찾기 $favorites개',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (decorated > 0) ...[
                          const SizedBox(height: 4),
                          Text('🎨 꾸민 기록 $decorated개',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (photos > 0) ...[
                          const SizedBox(height: 4),
                          Text('📷 사진 있는 기록 $photos개',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (journalNames.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('📓 ${journalNames.take(4).join(' · ')}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (longest != null) ...[
                          const SizedBox(height: 12),
                          _LongestEntryCard(
                            entry: longest,
                            chars: longest.content.trim().characters.length,
                          ),
                        ],
                      ],
                    ),
                  );
                }
                final e = entries[i - 1];
                final j = journalMap[e.journalId];
                return EntryCard(
                  e,
                  journalName: j?.title,
                  journalIcon: j?.displayIcon,
                  replyCount: replyCounts[e.entryId] ?? 0,
                  onTap: () => context.push('/entry/${e.entryId}'),
                );
              },
            ),
    );
  }
}

/// Tappable highlight for this day's longest record; opens the entry.
/// Mirrors tag/place/mood_entries_screen.dart's _LongestEntryCard for the day view.
class _LongestEntryCard extends StatelessWidget {
  const _LongestEntryCard({required this.entry, required this.chars});
  final DiaryEntry entry;
  final int chars;

  @override
  Widget build(BuildContext context) {
    final title = (entry.title?.trim().isNotEmpty ?? false)
        ? entry.title!.trim()
        : entry.content.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/entry/${entry.entryId}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📜 이 날의 가장 긴 기록 ($chars자)',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
            const SizedBox(height: 6),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
