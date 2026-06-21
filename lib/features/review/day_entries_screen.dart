import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
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
                  final header = mood == null
                      ? '이 날의 기록 ${entries.length}개'
                      : '이 날의 기록 ${entries.length}개 · ${mood.emoji}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(header,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
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
