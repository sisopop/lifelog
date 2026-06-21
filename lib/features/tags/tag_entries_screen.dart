import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('#$tag', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('이 태그의 기록이 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length + (related.isEmpty ? 0 : 1),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (related.isNotEmpty && i == 0) {
                  return _CoOccurringRow(tags: related);
                }
                final e = entries[i - (related.isEmpty ? 0 : 1)];
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
