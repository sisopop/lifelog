import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/mood_chip.dart';
import '../entries/entries_provider.dart';

/// Inline card shown on the detail screen when an entry has no mood yet,
/// inviting the user to attach one (without flagging the entry as "수정됨").
class MoodPickerCard extends ConsumerWidget {
  const MoodPickerCard({super.key, required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이 날의 기분은 어땠나요?',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in Mood.values)
                MoodChip(
                  m,
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref
                        .read(entriesProvider.notifier)
                        .setMood(entry, m);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('${m.emoji} ${m.label} 기분을 남겼어요'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to change or remove the mood of an entry that already has one
/// (opened by tapping the mood emoji in the header).
Future<void> showMoodSheet(
    BuildContext context, WidgetRef ref, DiaryEntry entry) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('기분 바꾸기',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in Mood.values)
                  MoodChip(
                    m,
                    selected: entry.mood == m,
                    onTap: () async {
                      Navigator.of(sheetCtx).pop();
                      await ref.read(entriesProvider.notifier).setMood(entry, m);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('${m.emoji} ${m.label}로 바꿨어요'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(sheetCtx).pop();
                await ref.read(entriesProvider.notifier).clearMood(entry);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('기분을 지웠어요'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('기분 지우기'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}
