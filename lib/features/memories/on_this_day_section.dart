import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/journal.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import 'on_this_day.dart';

/// Past entries written on today's calendar day (other years).
final onThisDayProvider = Provider<List<DiaryEntry>>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  return entriesOnThisDay(entries, DateTime.now());
});

/// Home banner that resurfaces "그날의 추억" — entries from this day in past
/// years. Renders nothing when there are no such memories.
class OnThisDaySection extends ConsumerWidget {
  const OnThisDaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(onThisDayProvider);
    if (memories.isEmpty) return const SizedBox.shrink();

    final journals = {
      for (final j in ref.watch(journalsProvider).asData?.value ?? const <Journal>[])
        j.journalId: j,
    };
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('🕰️', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text('그날의 추억',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('오늘과 같은 날, 지난날의 기록이에요',
            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 10),
        ...memories.map((e) {
          final j = journals[e.journalId];
          final years = yearsAgo(e.createdAt, now);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EntryCard(
              e,
              journalName: '$years년 전 · ${j?.title ?? '기록'}',
              journalIcon: j?.displayIcon,
              onTap: () => context.push('/entry/${e.entryId}'),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
