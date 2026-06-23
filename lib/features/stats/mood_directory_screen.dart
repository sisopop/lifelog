import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../entries/entries_provider.dart';
import 'mood_entries.dart';

/// Lists every recorded mood with its count, most-recorded first. Tapping a
/// row opens that mood's records. Reached from settings.
class MoodDirectoryScreen extends ConsumerWidget {
  const MoodDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final moods = moodCountsSorted(entries);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('기분 모아보기', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: moods.isEmpty
          ? const Center(
              child: Text('아직 기분이 기록된 글이 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: moods.length + 1,
              separatorBuilder: (_, i) =>
                  i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('기분 ${moods.length}종',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  );
                }
                final m = moods[i - 1];
                return ListTile(
                  leading: Text(m.key.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(m.key.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${m.value}개 기록'),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textHint),
                  onTap: () => context.push(
                    Uri(path: '/mood', queryParameters: {'m': m.key.name})
                        .toString(),
                  ),
                );
              },
            ),
    );
  }
}
