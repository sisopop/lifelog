import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../timeline/timeline_filter.dart';
import 'place_entries.dart';

/// Lists every record sharing a location (reached by tapping a place pin on
/// the entry detail). Each card opens the entry detail.
class PlaceEntriesScreen extends ConsumerWidget {
  const PlaceEntriesScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(entriesProvider).asData?.value ?? const [];
    final entries = entriesAtLocation(all, location);
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journalMap = {for (final j in journals) j.journalId: j};
    final replyCounts = replyCountsByParent(all);
    final span = placeDateSpan(all, location);
    final tags = tagsAtLocation(all, location, limit: 6);
    final mood = placeMood(all, location);
    final avgChars = averageCharsAtLocation(all, location);
    final favorites = favoriteCountAtLocation(all, location);
    final journalNames = journalIdsAtLocation(all, location)
        .map((id) => journalMap[id]?.title)
        .whereType<String>()
        .toList();
    final weekday = busiestWeekdayAtLocation(all, location);
    const weekdayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
    final dayPart = busiestDayPartAtLocation(all, location);
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
        title: Row(
          children: [
            const Icon(Icons.place, size: 20, color: AppColors.primaryDark),
            const SizedBox(width: 4),
            Flexible(
              child: Text(location,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('이 장소의 기록이 없어요',
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
                        Text('이 장소의 기록 ${entries.length}개',
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
                          Text(
                              '🏷 ${tags.map((t) => '#${t.key}').join(' ')}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint)),
                        ],
                        if (mood != null) ...[
                          const SizedBox(height: 4),
                          Text('${mood.emoji} 이곳에선 주로 ${mood.label}',
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
