import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../journals/default_journal_provider.dart';
import 'today_prompt.dart';

/// A gentle nudge shown on home only when today has no record yet, inviting
/// the user to jot a quick line. Hidden once they've written today.
class TodayPromptSection extends ConsumerWidget {
  const TodayPromptSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wroteToday = ref.watch(wroteTodayProvider);
    if (wroteToday) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘은 아직 기록이 없어요',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('한 줄이라도 남겨볼까요?',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('기록하기'),
              onPressed: () {
                final id = ref.read(defaultJournalProvider);
                context.push(writeRouteForJournal(ref, id));
              },
            ),
          ],
        ),
      ),
    );
  }
}
