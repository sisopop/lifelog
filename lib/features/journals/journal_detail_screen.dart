import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import 'journal_members_panel.dart';
import 'journal_repository.dart';
import 'journals_provider.dart';

/// A single journal's timeline: its entries, newest first, with a button to
/// add a new entry into this journal.
class JournalDetailScreen extends ConsumerWidget {
  const JournalDetailScreen({super.key, required this.journalId});

  final String journalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journal =
        journals.where((j) => j.journalId == journalId).firstOrNull;
    // Top-level entries only; 답장(reply) records render inside entry detail.
    final entries = (ref.watch(entriesProvider).asData?.value ?? const [])
        .where((e) => e.journalId == journalId && e.replyToEntryId == null)
        .toList();

    final color = journal != null ? Color(journal.coverColor) : AppColors.primary;
    final readOnly = journal?.isArchived ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            if (journal != null) ...[
              Text(journal.displayIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(journal?.title ?? '일기장',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          if (journal != null)
            _JournalMenu(journal: journal),
        ],
      ),
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton.extended(
              backgroundColor: color,
              onPressed: () => context.push('/write?journalId=$journalId'),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('기록', style: TextStyle(color: Colors.white)),
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (readOnly)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _ArchivedBanner(),
              ),
            // Shared journals (couple/exchange) show participants + invite.
            if (journal != null && journal.type != JournalType.personal)
              JournalMembersPanel(journal: journal),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    const Icon(Icons.edit_note,
                        size: 44, color: AppColors.textHint),
                    const SizedBox(height: 10),
                    Text(
                      readOnly
                          ? '보관된 일기장이에요.\n새 기록은 추가할 수 없어요.'
                          : '아직 기록이 없어요.\n오른쪽 아래 버튼으로 첫 기록을 남겨보세요.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textHint, height: 1.5),
                    ),
                  ],
                ),
              )
            else
              ...entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EntryCard(e,
                        onTap: () => context.push('/entry/${e.entryId}')),
                  )),
          ],
        ),
      ),
    );
  }
}

/// Journal management menu: rename, cover color, archive/unarchive, delete.
class _JournalMenu extends ConsumerWidget {
  const _JournalMenu({required this.journal});
  final Journal journal;

  static const _palette = [
    0xFF7C6FF0, 0xFFEF6F9E, 0xFF53B7A8, 0xFFF0A35E, 0xFF6FA8F0, 0xFF9B6FF0,
  ];

  bool get _isDefault =>
      journal.journalId == JournalRepository.defaultJournalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) async {
        final notifier = ref.read(journalsProvider.notifier);
        switch (v) {
          case 'rename':
            final name = await _promptName(context, journal.title);
            if (name != null && name.isNotEmpty) {
              await notifier.edit(journal.copyWith(title: name));
            }
          case 'color':
            final c = await _pickColor(context, journal.coverColor);
            if (c != null) await notifier.edit(journal.copyWith(coverColor: c));
          case 'archive':
            await notifier.edit(journal.copyWith(status: JournalStatus.ended));
          case 'unarchive':
            await notifier.edit(journal.copyWith(status: JournalStatus.active));
          case 'delete':
            final ok = await _confirmDelete(context);
            if (ok == true) {
              await notifier.delete(journal.journalId);
              if (context.mounted) context.pop();
            }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'rename', child: Text('이름 변경')),
        const PopupMenuItem(value: 'color', child: Text('표지색 변경')),
        if (journal.isArchived)
          const PopupMenuItem(value: 'unarchive', child: Text('보관 해제'))
        else
          const PopupMenuItem(value: 'archive', child: Text('보관(종료)')),
        if (!_isDefault)
          const PopupMenuItem(
            value: 'delete',
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Future<String?> _promptName(BuildContext context, String current) {
    final ctrl = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일기장 이름'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('저장')),
        ],
      ),
    );
  }

  Future<int?> _pickColor(BuildContext context, int current) {
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _palette.map((c) {
              final sel = c == current;
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, c),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: sel
                        ? Border.all(color: Colors.black87, width: 3)
                        : null,
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일기장 삭제'),
        content: const Text('일기장을 삭제할까요? 안의 기록은 사라지지 않지만\n목록에서 보이지 않게 돼요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _ArchivedBanner extends StatelessWidget {
  const _ArchivedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: AppColors.primaryDark),
          SizedBox(width: 8),
          Expanded(
            child: Text('보관된 일기장 — 읽기 전용으로 추억을 보관합니다.',
                style: TextStyle(fontSize: 13, color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
  }
}
