import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../entries/entries_provider.dart';
import 'tag_manage.dart';

/// Lists every tag with its usage count and lets the user rename or delete it
/// across all records at once.
class TagManageScreen extends ConsumerWidget {
  const TagManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final byName = ref.watch(tagSortByNameProvider);
    final tags = tagCountsSorted(entries, byName: byName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('태그 관리', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (tags.length > 1)
            TextButton.icon(
              onPressed: () =>
                  ref.read(tagSortByNameProvider.notifier).toggle(),
              icon: Icon(byName ? Icons.sort_by_alpha : Icons.tag,
                  size: 18, color: AppColors.primaryDark),
              label: Text(byName ? '이름순' : '빈도순',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark)),
            ),
        ],
      ),
      body: tags.isEmpty
          ? const Center(
              child: Text('아직 태그가 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: tags.length + 1,
              separatorBuilder: (_, i) =>
                  i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('태그 ${tags.length}개',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  );
                }
                final t = tags[i - 1];
                return ListTile(
                  leading: const Icon(Icons.tag, color: AppColors.primaryDark),
                  title: Text('#${t.key}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${t.value}개 기록'),
                  onTap: () => context.push(
                    Uri(path: '/tag', queryParameters: {'t': t.key}).toString(),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: '이름 변경',
                        onPressed: () => _rename(context, ref, t.key),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.moodHard),
                        tooltip: '삭제',
                        onPressed: () => _delete(context, ref, t.key, t.value),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, String tag) async {
    final ctrl = TextEditingController(text: tag);
    final messenger = ScaffoldMessenger.of(context);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('태그 이름 변경'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(prefixText: '#'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('변경')),
        ],
      ),
    );
    if (next == null) return;
    final trimmed = next.trim();
    if (trimmed.isEmpty || trimmed == tag) return;
    await ref.read(entriesProvider.notifier).renameTag(tag, trimmed);
    messenger.showSnackBar(
      SnackBar(content: Text('#$tag → #$trimmed 로 변경했어요')),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, String tag, int count) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('#$tag 삭제'),
        content: Text('$count개 기록에서 이 태그를 제거할까요?\n기록 자체는 삭제되지 않아요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제',
                  style: TextStyle(color: AppColors.moodHard))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(entriesProvider.notifier).deleteTag(tag);
    messenger.showSnackBar(SnackBar(content: Text('#$tag 태그를 삭제했어요')));
  }
}
