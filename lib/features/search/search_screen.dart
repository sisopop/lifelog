import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';
import '../../shared/widgets/entry_card.dart';
import '../../shared/widgets/mood_chip.dart';
import '../journals/journals_provider.dart';
import 'entry_search.dart';
import 'recent_searches.dart';

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
            hintText: '제목, 내용, 태그 검색',
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
      if (recent.isEmpty) {
        return const _Hint(
          icon: Icons.search,
          text: '기록을 검색해보세요',
        );
      }
      return _RecentList(
        terms: recent,
        onTap: _runRecent,
        onRemove: (t) =>
            ref.read(recentSearchesProvider.notifier).remove(t),
        onClear: () =>
            ref.read(recentSearchesProvider.notifier).clear(),
      );
    }
    final mood = ref.watch(searchMoodProvider);
    final journalId = ref.watch(searchJournalProvider);
    final onlyFavorites = ref.watch(searchFavoriteProvider);
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
        if (activeJournals.length > 1)
          _JournalFilterRow(
            journals: activeJournals,
            selectedId: journalId,
            onTap: (id) =>
                ref.read(searchJournalProvider.notifier).toggle(id),
          ),
        Expanded(
          child: results.isEmpty
              ? _Hint(
                  icon: Icons.search_off,
                  text: mood != null
                      ? "'$query' · ${mood.label} 결과가 없어요"
                      : "'$query'에 대한 결과가 없어요",
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

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.terms,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> terms;
  final void Function(String term) onTap;
  final void Function(String term) onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('최근 검색어',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              TextButton(
                onPressed: onClear,
                child: const Text('전체 삭제',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textHint)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: terms.length,
            itemBuilder: (_, i) {
              final term = terms[i];
              return ListTile(
                leading: const Icon(Icons.history,
                    size: 20, color: AppColors.textHint),
                title: Text(term,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textPrimary)),
                trailing: IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.textHint),
                  onPressed: () => onRemove(term),
                ),
                onTap: () => onTap(term),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
