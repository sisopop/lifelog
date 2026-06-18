import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
          return Column(
            children: [
              _FilterBar(filter: filter, tags: tags),
              Expanded(
                child: entries.isEmpty
                    ? _Empty(filtered: filter.isActive)
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
              ),
            ],
          );
        },
      ),
    );
  }
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
              Icon(icon, size: 14, color: AppColors.textSecondary),
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
