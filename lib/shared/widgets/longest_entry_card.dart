import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../models/diary_entry.dart';

/// Tappable highlight for the longest record in a scoped list
/// (day / tag / place / mood entries screens); opens the entry.
///
/// [scopeLabel] is the possessive noun shown in the header, e.g.
/// '이 날의' / '이 태그의' / '이 장소의' / '이 기분의'.
class LongestEntryCard extends StatelessWidget {
  const LongestEntryCard({
    super.key,
    required this.entry,
    required this.chars,
    required this.scopeLabel,
  });

  final DiaryEntry entry;
  final int chars;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final title = (entry.title?.trim().isNotEmpty ?? false)
        ? entry.title!.trim()
        : entry.content.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/entry/${entry.entryId}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📜 $scopeLabel 가장 긴 기록 ($chars자)',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
            const SizedBox(height: 6),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
