import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../memories/on_this_day_section.dart';
import '../memories/random_memory_section.dart';
import 'home_greeting.dart';
import 'home_journal_layout.dart';
import 'home_journals_view.dart';
import 'journal_activity.dart';
import 'today_prompt_section.dart';
import 'weekly_strip_section.dart';

/// Home = the user's list of journals (일기장 목록). Tapping a journal opens
/// its timeline; "+ 새 일기장" launches the 3-step creation wizard.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final todayLabel = DateFormat.yMMMMEEEEd(locale).format(now);
    final greeting = greetingForHour(now.hour);
    final journalsAsync = ref.watch(journalsProvider);
    final rawJournals = journalsAsync.asData?.value ?? const [];
    // A read failure (e.g. a stuck schema) must NOT look like "no journals" —
    // show a recoverable error instead of the empty "새 일기장" tile.
    final journalsFailed = journalsAsync.hasError && rawJournals.isEmpty;
    final counts =
        ref.watch(journalEntryCountsProvider).asData?.value ?? const {};
    final allEntries = ref.watch(entriesProvider).asData?.value ?? const [];
    final byActivity = ref.watch(homeJournalSortProvider);
    final layout = ref.watch(homeJournalLayoutProvider);
    final journals = byActivity
        ? sortJournalsByActivity(rawJournals, allEntries)
        : rawJournals;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(todayLabel,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textHint)),
                      const SizedBox(height: 4),
                      Text(greeting,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                if (journals.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: IconButton(
                        icon: Icon(
                            byActivity ? Icons.history : Icons.sort,
                            color: AppColors.primary),
                        tooltip: byActivity ? '최근 활동순' : '기본 순서',
                        onPressed: () => ref
                            .read(homeJournalSortProvider.notifier)
                            .toggle(),
                      ),
                    ),
                  ),
                if (journals.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: IconButton(
                        icon: const Icon(Icons.library_add_outlined,
                            color: AppColors.primary),
                        tooltip: '새 일기장',
                        onPressed: () => context.push('/journal/new'),
                      ),
                    ),
                  ),
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: IconButton(
                    icon: const Icon(Icons.person, color: AppColors.primary),
                    onPressed: () => context.push('/settings'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // The journals are the hero: a bookshelf grid right under the
            // header, with "새 일기장" as the trailing tile.
            if (journalsFailed)
              _JournalLoadError(
                onRetry: () => ref.invalidate(journalsProvider),
              )
            else if (journals.isEmpty)
              _NewJournalCard(onTap: () => context.push('/journal/new'))
            else
              HomeJournalsView(
                journals: journals,
                counts: counts,
                layout: layout,
              ),
            const SizedBox(height: 20),
            const TodayPromptSection(),
            const WeeklyStripSection(),
            const SizedBox(height: 16),
            const OnThisDaySection(),
            const RandomMemorySection(),
            if (journals.isEmpty && !journalsFailed)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text('아직 일기장이 없어요.\n첫 일기장을 만들어보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textHint, height: 1.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown when journals fail to load (vs. genuinely having none). Reassures the
/// user their data is safe and offers a retry that re-reads the DB.
class _JournalLoadError extends StatelessWidget {
  const _JournalLoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.moodHard, width: 1.2),
        color: AppColors.moodHard.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: AppColors.moodHard),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('일기장을 불러오지 못했어요',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('기록은 안전하게 보관되어 있어요. 잠시 후 다시 시도해 주세요.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewJournalCard extends StatelessWidget {
  const _NewJournalCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.4),
          color: AppColors.primarySoft.withValues(alpha: 0.4),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary),
            SizedBox(width: 10),
            Text('새 일기장 만들기',
                style: TextStyle(
                    color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

