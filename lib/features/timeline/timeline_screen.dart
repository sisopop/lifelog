import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import 'timeline_filter.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(ref.watch(timelineSortProvider)
                ? Icons.arrow_upward
                : Icons.arrow_downward),
            tooltip: ref.watch(timelineSortProvider) ? '오래된순' : '최신순',
            onPressed: () => ref.read(timelineSortProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: '캘린더',
            onPressed: () => context.push('/calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: '즐겨찾기',
            onPressed: () => context.push('/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '검색',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패: $e')),
        data: (_) {
          final filter = ref.watch(timelineFilterProvider);
          final entries = ref.watch(filteredTimelineProvider);
          final tags = ref.watch(availableTagsProvider);
          final journals = ref.watch(journalsProvider).asData?.value ?? const [];
          final journalMap = {for (final j in journals) j.journalId: j};
          final replyCounts = replyCountsByParent(
              entriesAsync.asData?.value ?? const []);
          final groups = groupByMonth(entries);
          final locale = Localizations.localeOf(context).toLanguageTag();
          return Column(
            children: [
              _FilterBar(filter: filter, tags: tags),
              Expanded(
                child: entries.isEmpty
                    ? _Empty(filtered: filter.isActive)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: groups.length,
                        itemBuilder: (_, gi) {
                          final g = groups[gi];
                          final label = DateFormat.yMMMM(locale)
                              .format(DateTime(g.year, g.month));
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    top: gi == 0 ? 4 : 20, bottom: 10),
                                child: Text(
                                  '$label · ${g.entries.length}개',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              for (final e in g.entries)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: EntryCard(
                                    e,
                                    journalName: journalMap[e.journalId]?.title,
                                    journalIcon:
                                        journalMap[e.journalId]?.displayIcon,
                                    replyCount: replyCounts[e.entryId] ?? 0,
                                    onTap: () =>
                                        context.push('/entry/${e.entryId}'),
                                    onLongPress: () =>
                                        _toggleFavorite(context, ref, e),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Quick-toggles an entry's favorite flag from the list with haptic feedback
/// and a confirming snackbar.
Future<void> _toggleFavorite(
    BuildContext context, WidgetRef ref, DiaryEntry entry) async {
  HapticFeedback.lightImpact();
  final messenger = ScaffoldMessenger.of(context);
  await ref.read(entriesProvider.notifier).toggleFavorite(entry);
  messenger.showSnackBar(
    SnackBar(
      content: Text(entry.isFavorite ? '즐겨찾기에서 뺐어요' : '즐겨찾기에 추가했어요'),
      duration: const Duration(seconds: 1),
    ),
  );
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter, required this.tags});
  final TimelineFilter filter;
  final List<String> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timelineFilterProvider.notifier);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          for (final p in const [
            DatePreset.week,
            DatePreset.month,
            DatePreset.year
          ]) ...[
            _Chip(
              label: p.label,
              selected: filter.period == p,
              onTap: () => notifier.togglePeriod(p),
            ),
            const SizedBox(width: 8),
          ],
          _Chip(
            label: '즐겨찾기',
            selected: filter.favorite,
            icon: filter.favorite ? Icons.star : Icons.star_border,
            onTap: notifier.toggleFavorite,
          ),
          const SizedBox(width: 8),
          for (final m in Mood.values) ...[
            _Chip(
              label: '${m.emoji} ${m.label}',
              selected: filter.mood == m,
              onTap: () => notifier.toggleMood(m),
            ),
            const SizedBox(width: 8),
          ],
          for (final t in tags) ...[
            _Chip(
              label: '#$t',
              selected: filter.tag == t,
              onTap: () => notifier.toggleTag(t),
            ),
            const SizedBox(width: 8),
          ],
          if (filter.isActive)
            _Chip(
              label: '초기화',
              selected: false,
              icon: Icons.close,
              onTap: notifier.clear,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.amber : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color:
                    selected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({this.filtered = false});
  final bool filtered;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(filtered ? Icons.filter_alt_off : Icons.edit_note,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(filtered ? '조건에 맞는 기록이 없어요' : '첫 기록을 남겨보세요',
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
