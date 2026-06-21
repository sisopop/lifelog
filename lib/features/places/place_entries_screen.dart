import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                    child: Text('이 장소의 기록 ${entries.length}개',
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
