import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/journal.dart';
import '../../shared/widgets/entry_card.dart';
import '../journals/journals_provider.dart';
import 'random_memory.dart';

/// Home card that resurfaces a random past entry to revisit. The 🎲 button
/// draws a different memory. Renders nothing when there are no past records.
class RandomMemorySection extends ConsumerWidget {
  const RandomMemorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memory = ref.watch(randomMemoryProvider);
    if (memory == null) return const SizedBox.shrink();

    final journals = {
      for (final j
          in ref.watch(journalsProvider).asData?.value ?? const <Journal>[])
        j.journalId: j,
    };
    final j = journals[memory.journalId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎲', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            const Expanded(
              child: Text('다시 꺼내보기',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),
            IconButton(
              tooltip: '다른 기록',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.casino_outlined,
                  size: 20, color: AppColors.primaryDark),
              onPressed: () =>
                  ref.read(randomMemorySeedProvider.notifier).shuffle(),
            ),
          ],
        ),
        const Text('잊고 있던 지난 기록을 다시 만나보세요',
            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 10),
        EntryCard(
          memory,
          journalName: j?.title ?? '기록',
          journalIcon: j?.displayIcon,
          onTap: () => context.push('/entry/${memory.entryId}'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
