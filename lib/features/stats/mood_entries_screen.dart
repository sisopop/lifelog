import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../timeline/timeline_filter.dart';
import 'mood_entries.dart';

/// Lists every record sharing a [mood] (reached by tapping a slice of the
/// 감정 분포 chart on the lifetime summary). Each card opens the entry detail.
class MoodEntriesScreen extends ConsumerWidget {
  const MoodEntriesScreen({super.key, required this.mood});

  final Mood mood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(entriesProvider).asData?.value ?? const [];
    final entries = entriesWithMood(all, mood);
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journalMap = {for (final j in journals) j.journalId: j};
    final replyCounts = replyCountsByParent(all);
    final span = moodDateSpan(all, mood);
    final tags = tagsWithMood(all, mood, limit: 6);
    final places = placesWithMood(all, mood, limit: 4);
    final avgChars = averageCharsWithMood(all, mood);
    final favorites = favoriteCountWithMood(all, mood);
    final decorated = decoratedCountWithMood(all, mood);
    final photos = photoCountWithMood(all, mood);
    final journalNames = journalIdsWithMood(all, mood)
        .map((id) => journalMap[id]?.title)
        .whereType<String>()
        .toList();
    final weekday = busiestWeekdayWithMood(all, mood);
    const weekdayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
    final dayPart = busiestDayPartWithMood(all, mood);
    const dayPartNames = ['새벽', '아침', '오후', '저녁'];
    final longest = longestEntryWithMood(all, mood);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final md = DateFormat.MMMMd(locale);
    final spanText = span == null
        ? null
        : span.first == span.last
            ? '📅 ${md.format(span.first)}'
            : '📅 ${md.format(span.first)} – ${md.format(span.last)}';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text('${mood.label} 기록',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('이 기분의 기록이 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${mood.label} 기록 ${entries.length}개',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                        if (spanText != null) ...[
                          const SizedBox(height: 4),
                          Text(spanText,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('🏷 ${tags.map((t) => '#${t.key}').join(' ')}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (places.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('📍 ${places.join(' · ')}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (avgChars > 0) ...[
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
                        if (weekday != null) ...[
                          const SizedBox(height: 4),
                          Text('📆 주로 ${weekdayNames[weekday]}요일',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (dayPart != null) ...[
                          const SizedBox(height: 4),
                          Text('🕘 주로 ${dayPartNames[dayPart]}에 기록',
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

/// Tappable highlight for this mood's longest record; opens the entry.
/// Mirrors tag_entries_screen.dart's _LongestEntryCard for the mood view.
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
            Text('📜 이 기분의 가장 긴 기록 ($chars자)',
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
