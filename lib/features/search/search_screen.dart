import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';
import '../../shared/widgets/entry_card.dart';
import '../../shared/widgets/mood_chip.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../places/place_directory.dart';
import '../timeline/timeline_filter.dart' show availableTagsProvider, DatePreset;
import 'entry_search.dart';
import 'recent_searches.dart';

part 'search_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (value.trim().isEmpty) return;
    ref.read(recentSearchesProvider.notifier).add(value);
  }

  void _runRecent(String term) {
    _ctrl.text = term;
    _ctrl.selection =
        TextSelection.collapsed(offset: term.length);
    ref.read(searchQueryProvider.notifier).set(term);
    ref.read(recentSearchesProvider.notifier).add(term);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '제목, 내용, 태그, 장소 검색',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).set(v),
          onSubmitted: _submit,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                ref.read(searchQueryProvider.notifier).set('');
                ref.read(searchMoodProvider.notifier).clear();
                ref.read(searchJournalProvider.notifier).clear();
                ref.read(searchFavoriteProvider.notifier).clear();
                ref.read(searchSortProvider.notifier).clear();
                ref.read(searchPeriodProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: _buildBody(context, query, results),
    );
  }

  Widget _buildBody(BuildContext context, String query, List results) {
    if (query.trim().isEmpty) {
      final recent = ref.watch(recentSearchesProvider);
      final tags = ref.watch(availableTagsProvider).take(12).toList();
      final allEntries = ref.watch(entriesProvider).asData?.value ?? const [];
      final places =
          placeCountsSorted(allEntries).take(8).map((e) => e.key).toList();
      if (recent.isEmpty && tags.isEmpty && places.isEmpty) {
        return const _Hint(
          icon: Icons.search,
          text: '기록을 검색해보세요',
        );
      }
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tags.isNotEmpty) _SuggestedTags(tags: tags, onTap: _runRecent),
            if (places.isNotEmpty)
              _SuggestedPlaces(places: places, onTap: _runRecent),
            if (recent.isNotEmpty)
              _RecentList(
                terms: recent,
                onTap: _runRecent,
                onRemove: (t) =>
                    ref.read(recentSearchesProvider.notifier).remove(t),
                onClear: () =>
                    ref.read(recentSearchesProvider.notifier).clear(),
              ),
          ],
        ),
      );
    }
    final mood = ref.watch(searchMoodProvider);
    final journalId = ref.watch(searchJournalProvider);
    final onlyFavorites = ref.watch(searchFavoriteProvider);
    final period = ref.watch(searchPeriodProvider);
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journalMap = {for (final j in journals) j.journalId: j};
    final activeJournals = journals.where((j) => !j.isArchived).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MoodFilterRow(
          selected: mood,
          onTap: (m) => ref.read(searchMoodProvider.notifier).toggle(m),
          favorite: onlyFavorites,
          onFavoriteTap: () =>
              ref.read(searchFavoriteProvider.notifier).toggle(),
        ),
        _PeriodFilterRow(
          selected: period,
          onTap: (p) => ref.read(searchPeriodProvider.notifier).toggle(p),
        ),
        if (activeJournals.length > 1)
          _JournalFilterRow(
            journals: activeJournals,
            selectedId: journalId,
            onTap: (id) =>
                ref.read(searchJournalProvider.notifier).toggle(id),
          ),
        Expanded(
          child: results.isEmpty
              ? _NoResults(
                  query: query,
                  mood: mood,
                  tags: ref.watch(availableTagsProvider).take(8).toList(),
                  onTagTap: _runRecent,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: results.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      final ascending = ref.watch(searchSortProvider);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text('${results.length}개 찾음',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                            const Spacer(),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => ref
                                  .read(searchSortProvider.notifier)
                                  .toggle(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        ascending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 14,
                                        color: AppColors.primaryDark),
                                    const SizedBox(width: 4),
                                    Text(ascending ? '오래된순' : '최신순',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryDark)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final e = results[i - 1];
                    final j = journalMap[e.journalId];
                    return EntryCard(
                      e,
                      journalName: j?.title,
                      journalIcon: j?.displayIcon,
                      highlight: query,
                      onTap: () => context.push('/entry/${e.entryId}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Horizontal mood chips (plus a favorites toggle) that scope the results.
class _MoodFilterRow extends StatelessWidget {
  const _MoodFilterRow({
    required this.selected,
    required this.onTap,
    required this.favorite,
    required this.onFavoriteTap,
  });

  final Mood? selected;
  final void Function(Mood mood) onTap;
  final bool favorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          for (final m in Mood.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MoodChip(
                m,
                selected: selected == m,
                onTap: () => onTap(m),
              ),
            ),
          FilterChip(
            avatar: Icon(
              favorite ? Icons.star : Icons.star_border,
              size: 18,
              color: favorite ? Colors.amber : AppColors.textSecondary,
            ),
            label: const Text('즐겨찾기'),
            selected: favorite,
            onSelected: (_) => onFavoriteTap(),
            showCheckmark: false,
            selectedColor: AppColors.primarySoft,
            labelStyle: TextStyle(
              fontSize: 13,
              color: favorite ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: favorite ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal journal chips that scope the search results to one journal.
class _JournalFilterRow extends StatelessWidget {
  const _JournalFilterRow({
    required this.journals,
    required this.selectedId,
    required this.onTap,
  });

  final List<Journal> journals;
  final String? selectedId;
  final void Function(String journalId) onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: journals
            .map((j) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${j.displayIcon} ${j.title}'),
                    selected: selectedId == j.journalId,
                    onSelected: (_) => onTap(j.journalId),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: selectedId == j.journalId
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      fontWeight: selectedId == j.journalId
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/// Horizontal date-range chips (전체 / 오늘 / 이번 주 / 이번 달 / 올해) that
/// scope the search results by creation date.
class _PeriodFilterRow extends StatelessWidget {
  const _PeriodFilterRow({required this.selected, required this.onTap});

  final DatePreset selected;
  final void Function(DatePreset preset) onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          for (final p in DatePreset.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p.label),
                selected: selected == p,
                onSelected: (_) => onTap(p),
                selectedColor: AppColors.primarySoft,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: selected == p
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontWeight:
                      selected == p ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
