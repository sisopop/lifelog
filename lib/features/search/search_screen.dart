import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/entry_card.dart';
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
    if (results.isEmpty) {
      return _Hint(
        icon: Icons.search_off,
        text: "'$query'에 대한 결과가 없어요",
      );
    }
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journalMap = {for (final j in journals) j.journalId: j};
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final e = results[i];
        final j = journalMap[e.journalId];
        return EntryCard(
          e,
          journalName: j?.title,
          journalIcon: j?.displayIcon,
          highlight: query,
          onTap: () => context.push('/entry/${e.entryId}'),
        );
      },
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
