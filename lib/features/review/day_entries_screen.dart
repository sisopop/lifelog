import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import 'day_entries.dart';

/// Lists the records of a single day (reached by tapping a day on the
/// 회고 calendar). Each card opens the entry detail.
class DayEntriesScreen extends ConsumerWidget {
  const DayEntriesScreen({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = DateFormat.yMMMMd(locale).format(day);
    final all = ref.watch(entriesProvider).asData?.value ?? const [];
    final entries = entriesOfDay(all, day);
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journalMap = {for (final j in journals) j.journalId: j};

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text('이 날의 기록이 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final e = entries[i];
                final j = journalMap[e.journalId];
                return EntryCard(
                  e,
                  journalName: j?.title,
                  journalIcon: j?.displayIcon,
                  onTap: () => context.push('/entry/${e.entryId}'),
                );
              },
            ),
    );
  }
}
