import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../entries/entries_provider.dart';
import 'related_entries.dart';

/// A compact "관련 기록" list under an entry: other records that share a tag,
/// each tappable to open its detail. Hidden entirely when there are none.
class RelatedEntriesSection extends ConsumerWidget {
  const RelatedEntriesSection({super.key, required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(entriesProvider).asData?.value ?? const [];
    final related = relatedEntries(all, entry);
    if (related.isEmpty) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('관련 기록',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final e in related) _RelatedTile(entry: e, locale: locale),
      ],
    );
  }
}

class _RelatedTile extends StatelessWidget {
  const _RelatedTile({required this.entry, required this.locale});
  final DiaryEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final raw = (entry.title?.trim().isNotEmpty ?? false)
        ? entry.title!.trim()
        : entry.content.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/entry/${entry.entryId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                raw.isEmpty ? '제목 없음' : raw,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Text(DateFormat('M.d', locale).format(entry.createdAt),
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}
