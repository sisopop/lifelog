part of 'search_screen.dart';

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

/// Tappable "popular tags" chips shown on the empty-query start screen so the
/// user can jump straight into a tag search. Reuses the timeline's usage-ranked
/// tag list.
class _SuggestedTags extends StatelessWidget {
  const _SuggestedTags({
    required this.tags,
    required this.onTap,
    this.title = '자주 쓰는 태그',
  });

  final List<String> tags;
  final void Function(String term) onTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                ActionChip(
                  label: Text('#$t'),
                  onPressed: () => onTap(t),
                  backgroundColor: AppColors.primarySoft,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Empty-results view: the "no matches" hint plus a few tag chips the user can
/// tap to pivot into a tag search.
class _NoResults extends StatelessWidget {
  const _NoResults({
    required this.query,
    required this.mood,
    required this.tags,
    required this.onTagTap,
  });

  final String query;
  final Mood? mood;
  final List<String> tags;
  final void Function(String term) onTagTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 48, bottom: 20),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            mood != null
                ? "'$query' · ${mood!.label} 결과가 없어요"
                : "'$query'에 대한 결과가 없어요",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (tags.isNotEmpty)
            _SuggestedTags(
              tags: tags,
              onTap: onTagTap,
              title: '이런 태그는 어때요?',
            ),
        ],
      ),
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
