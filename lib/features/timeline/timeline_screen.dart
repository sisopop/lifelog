import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('기록', style: TextStyle(fontWeight: FontWeight.w800))),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패: $e')),
        data: (all) {
          // Show top-level entries only; replies live in entry detail.
          final entries =
              all.where((e) => e.replyToEntryId == null).toList();
          return entries.isEmpty
              ? const _Empty()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => EntryCard(
                    entries[i],
                    onTap: () => context.push('/entry/${entries[i].entryId}'),
                  ),
                );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, size: 64, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('첫 기록을 남겨보세요', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
