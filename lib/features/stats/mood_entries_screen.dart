import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
                    child: Text('${mood.label} 기록 ${entries.length}개',
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
