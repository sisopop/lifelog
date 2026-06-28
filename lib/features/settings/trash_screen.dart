import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/journal.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import 'trash_provider.dart';
import 'trash_retention.dart';

/// 휴지통: soft-delete된 일기장·기록을 복원하거나 영구 삭제하는 화면.
/// 30일이 지나면 자동으로 영구 삭제된다.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashAsync = ref.watch(trashProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('휴지통')),
      body: trashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _TrashMessage(
          icon: Icons.error_outline,
          text: '휴지통을 불러오지 못했어요.',
        ),
        data: (trash) {
          if (trash.isEmpty) {
            return const _TrashMessage(
              icon: Icons.delete_outline,
              text: '휴지통이 비어 있어요.\n삭제한 일기장과 기록이 30일 동안 여기 보관돼요.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              const _RetentionNote(),
              if (trash.journals.isNotEmpty) ...[
                const _SectionHeader('일기장'),
                for (final j in trash.journals)
                  _JournalTrashTile(journal: j, now: now),
              ],
              if (trash.entries.isNotEmpty) ...[
                const _SectionHeader('기록'),
                for (final e in trash.entries)
                  _EntryTrashTile(entry: e, now: now),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RetentionNote extends StatelessWidget {
  const _RetentionNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        '삭제한 항목은 30일 동안 보관된 뒤 자동으로 사라져요.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _JournalTrashTile extends ConsumerWidget {
  const _JournalTrashTile({required this.journal, required this.now});
  final Journal journal;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedAt = journal.deletedAt;
    return _TrashCard(
      leading: Text(journal.displayIcon, style: const TextStyle(fontSize: 22)),
      title: journal.title,
      subtitle: deletedAt == null ? null : trashRetentionLabel(deletedAt, now),
      onRestore: () async {
        if (deletedAt == null) return;
        final messenger = ScaffoldMessenger.of(context);
        await ref
            .read(journalsProvider.notifier)
            .restore(journal.journalId, deletedAt);
        _toast(messenger, '일기장을 복원했어요');
      },
      onDeleteForever: () async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await _confirmForever(
          context,
          '일기장 영구 삭제',
          '이 일기장과 안의 기록을 완전히 삭제할까요?\n되돌릴 수 없어요.',
        );
        if (ok != true) return;
        await ref
            .read(journalsProvider.notifier)
            .deleteForever(journal.journalId);
        _toast(messenger, '영구 삭제했어요');
      },
    );
  }
}

class _EntryTrashTile extends ConsumerWidget {
  const _EntryTrashTile({required this.entry, required this.now});
  final DiaryEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedAt = entry.deletedAt;
    final title = (entry.title?.trim().isNotEmpty ?? false)
        ? entry.title!.trim()
        : _preview(entry.content);
    return _TrashCard(
      leading: const Icon(Icons.article_outlined, color: AppColors.primary),
      title: title,
      subtitle: deletedAt == null ? null : trashRetentionLabel(deletedAt, now),
      onRestore: () async {
        final messenger = ScaffoldMessenger.of(context);
        await ref.read(entriesProvider.notifier).restore(entry.entryId);
        _toast(messenger, '기록을 복원했어요');
      },
      onDeleteForever: () async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await _confirmForever(
          context,
          '기록 영구 삭제',
          '이 기록을 완전히 삭제할까요?\n되돌릴 수 없어요.',
        );
        if (ok != true) return;
        await ref.read(entriesProvider.notifier).deleteForever(entry.entryId);
        _toast(messenger, '영구 삭제했어요');
      },
    );
  }
}

class _TrashCard extends StatelessWidget {
  const _TrashCard({
    required this.leading,
    required this.title,
    required this.onRestore,
    required this.onDeleteForever,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: leading,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '복원',
              icon: const Icon(Icons.restore_from_trash_outlined,
                  color: AppColors.primary),
              onPressed: onRestore,
            ),
            IconButton(
              tooltip: '영구 삭제',
              icon: const Icon(Icons.delete_forever_outlined,
                  color: AppColors.moodHard),
              onPressed: onDeleteForever,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashMessage extends StatelessWidget {
  const _TrashMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _preview(String content) {
  final firstLine = content.trim().split('\n').first.trim();
  return firstLine.isEmpty ? '(내용 없음)' : firstLine;
}

void _toast(ScaffoldMessengerState messenger, String msg) {
  messenger.showSnackBar(SnackBar(content: Text(msg)));
}

Future<bool?> _confirmForever(
    BuildContext context, String title, String body) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('영구 삭제', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
