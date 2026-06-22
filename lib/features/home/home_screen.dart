import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/journal.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../memories/on_this_day_section.dart';
import '../memories/random_memory_section.dart';
import 'home_greeting.dart';
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
    final rawJournals = ref.watch(journalsProvider).asData?.value ?? const [];
    final counts =
        ref.watch(journalEntryCountsProvider).asData?.value ?? const {};
    final allEntries = ref.watch(entriesProvider).asData?.value ?? const [];
    final byActivity = ref.watch(homeJournalSortProvider);
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
            if (journals.isEmpty)
              _NewJournalCard(onTap: () => context.push('/journal/new'))
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.74,
                children: [
                  for (final j in journals)
                    _JournalBook(
                      journal: j,
                      entryCount: counts[j.journalId] ?? 0,
                      onTap: () => context.push('/journal/${j.journalId}'),
                    ),
                  _AddJournalBook(onTap: () => context.push('/journal/new')),
                ],
              ),
            const SizedBox(height: 20),
            const TodayPromptSection(),
            const WeeklyStripSection(),
            const SizedBox(height: 16),
            const OnThisDaySection(),
            const RandomMemorySection(),
            if (journals.isEmpty)
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

/// A journal shown as a book cover. Structured so a future "skin" system can
/// swap the cover decoration (color → gradient → pattern → texture) without
/// touching the layout. For now it shows icon · title · record count only.
class _JournalBook extends StatelessWidget {
  const _JournalBook({
    required this.journal,
    required this.entryCount,
    required this.onTap,
  });
  final Journal journal;
  final int entryCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(journal.coverColor);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Spine accent on the left edge to read as a book.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$entryCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(journal.displayIcon,
                      style: const TextStyle(fontSize: 34)),
                  Text(journal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trailing "새 일기장" tile that matches the book grid.
class _AddJournalBook extends StatelessWidget {
  const _AddJournalBook({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.4),
          color: AppColors.primarySoft.withValues(alpha: 0.4),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primary, size: 30),
            SizedBox(height: 8),
            Text('새 일기장',
                style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
