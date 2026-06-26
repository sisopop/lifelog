import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/journal.dart';
import '../decorate/cover_decorate_sheet.dart';
import '../decorate/journal_cover.dart';
import 'home_journal_layout.dart';

/// Renders the home journal list in the layout the user picked: a full-width
/// card list, or a 2/3/4-column grid of book covers. The cover widgets are
/// structured so a future "skin" system can swap their decoration without
/// changing the layout. Long-pressing a cover opens the 꾸미기 (decorate) sheet.
class HomeJournalsView extends ConsumerWidget {
  const HomeJournalsView({
    super.key,
    required this.journals,
    required this.counts,
    required this.layout,
  });

  final List<Journal> journals;
  final Map<String, int> counts;
  final HomeJournalLayout layout;

  void _open(BuildContext context, Journal j) =>
      context.push('/journal/${j.journalId}');
  void _add(BuildContext context) => context.push('/journal/new');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int countOf(Journal j) => counts[j.journalId] ?? 0;
    void decorate(Journal j) => showCoverDecorateSheet(context, ref, j);

    if (layout == HomeJournalLayout.card) {
      return Column(
        children: [
          for (final j in journals)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _JournalCard(
                journal: j,
                entryCount: countOf(j),
                onTap: () => _open(context, j),
                onLongPress: () => decorate(j),
              ),
            ),
          _AddJournalCard(onTap: () => _add(context)),
        ],
      );
    }

    final cols = layout.crossAxisCount;
    final appIcon = layout == HomeJournalLayout.grid4;
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: appIcon ? 0.74 : (cols == 2 ? 0.74 : 0.78),
      children: [
        for (final j in journals)
          if (appIcon)
            _JournalAppIcon(
              journal: j,
              entryCount: countOf(j),
              onTap: () => _open(context, j),
              onLongPress: () => decorate(j),
            )
          else
            _JournalBook(
              journal: j,
              entryCount: countOf(j),
              compact: cols >= 3,
              onTap: () => _open(context, j),
              onLongPress: () => decorate(j),
            ),
        if (appIcon)
          _AddJournalAppIcon(onTap: () => _add(context))
        else
          _AddJournalBook(onTap: () => _add(context)),
      ],
    );
  }
}

/// Full-width horizontal card (icon · title · count · chevron).
class _JournalCard extends StatelessWidget {
  const _JournalCard({
    required this.journal,
    required this.entryCount,
    required this.onTap,
    this.onLongPress,
  });
  final Journal journal;
  final int entryCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = Color(journal.coverColor);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: coverBoxDecoration(color, 18),
        child: Row(
          children: [
            Text(journal.displayIcon, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(journal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('기록 $entryCount개',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// Book cover with the title inside (used by the 2- and 3-column grids).
class _JournalBook extends StatelessWidget {
  const _JournalBook({
    required this.journal,
    required this.entryCount,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
  });
  final Journal journal;
  final int entryCount;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      onLongPress: onLongPress,
      child: JournalCover(
        color: journal.coverColor,
        icon: journal.displayIcon,
        pattern: journal.coverPattern,
        binding: journal.coverBinding,
        corner: journal.coverCorner,
        band: journal.coverBand,
        ribbon: journal.coverRibbon,
        title: journal.title,
        entryCount: entryCount,
        radius: 14,
        iconSize: compact ? 26 : 34,
        titleSize: compact ? 12 : 15,
      ),
    );
  }
}

/// App-icon style: a small square cover with the title below it in dark text.
class _JournalAppIcon extends StatelessWidget {
  const _JournalAppIcon({
    required this.journal,
    required this.entryCount,
    required this.onTap,
    this.onLongPress,
  });
  final Journal journal;
  final int entryCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: JournalCover(
              color: journal.coverColor,
              icon: journal.displayIcon,
              pattern: journal.coverPattern,
              binding: journal.coverBinding,
              corner: journal.coverCorner,
              band: journal.coverBand,
              ribbon: journal.coverRibbon,
              entryCount: entryCount,
              radius: 16,
              iconSize: 28,
              centerIcon: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(journal.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Trailing "새 일기장" tile for the card list.
class _AddJournalCard extends StatelessWidget {
  const _AddJournalCard({required this.onTap});
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
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700)),
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
            Icon(Icons.add, color: AppColors.primary, size: 24),
            SizedBox(height: 6),
            Text('새 일기장',
                style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Trailing "새 일기장" tile for the app-icon grid (square + label below).
class _AddJournalAppIcon extends StatelessWidget {
  const _AddJournalAppIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.4),
                color: AppColors.primarySoft.withValues(alpha: 0.4),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          const Text('새 일기장',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
