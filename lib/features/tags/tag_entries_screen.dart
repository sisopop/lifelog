import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../timeline/timeline_filter.dart';
import 'tag_entries.dart';

/// Lists every record carrying a given tag (reached by tapping a tag chip).
/// Each card opens the entry detail.
class TagEntriesScreen extends ConsumerWidget {
  const TagEntriesScreen({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(entriesProvider).asData?.value ?? const [];
    final entries = entriesWithTag(all, tag);
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journalMap = {for (final j in journals) j.journalId: j};
    final replyCounts = replyCountsByParent(all);
    final related = coOccurringTags(all, tag);
    final span = tagDateSpan(all, tag);
    final mood = tagMood(all, tag);
    final places = placesWithTag(all, tag, limit: 4);
    final avgChars = averageCharsWithTag(all, tag);
    final favorites = favoriteCountWithTag(all, tag);
    final journalNames = journalIdsWithTag(all, tag)
        .map((id) => journalMap[id]?.title)
        .whereType<String>()
        .toList();
    final weekday = busiestWeekdayWithTag(all, tag);
    const weekdayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
    final dayPart = busiestDayPartWithTag(all, tag);
    const dayPartNames = ['새벽', '아침', '오후', '저녁'];
    final locale = Localizations.localeOf(context).toLanguageTag();
    final md = DateFormat.MMMMd(locale);
    final spanText = span == null
        ? null
        : span.first == span.last
            ? '📅 ${md.format(span.first)}'
            : '📅 ${md.format(span.first)} – ${md.format(span.last)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            entries.isEmpty ? '#$tag' : '#$tag · ${entries.length}개',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('이 태그의 기록이 없어요',
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
                        if (spanText != null)
                          Text(spanText,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                        if (mood != null) ...[
                          const SizedBox(height: 4),
                          Text('${mood.emoji} 이 태그엔 주로 ${mood.label}',
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
                        if (related.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _CoOccurringRow(tags: related),
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

/// "함께 쓴 태그" chips shown above a tag's records; each opens that tag.
class _CoOccurringRow extends StatelessWidget {
  const _CoOccurringRow({required this.tags});
  final List<MapEntry<String, int>> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('함께 쓴 태그',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in tags)
              ActionChip(
                label: Text('#${t.key} ${t.value}'),
                backgroundColor: AppColors.primarySoft,
                labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark),
                side: BorderSide.none,
                onPressed: () => context.push(
                    Uri(path: '/tag', queryParameters: {'t': t.key})
                        .toString()),
              ),
          ],
        ),
      ],
    );
  }
}
