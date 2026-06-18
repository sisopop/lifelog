import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/entry_card.dart';
import '../journals/journals_provider.dart';
import 'entry_search.dart';

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
      return const _Hint(
        icon: Icons.search,
        text: '기록을 검색해보세요',
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
          onTap: () => context.push('/entry/${e.entryId}'),
        );
      },
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
