import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';
import '../../shared/models/journal_member.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../export/export_markdown.dart';
import '../stats/lifetime_stats.dart';
import 'journal_members_panel.dart';
import 'journal_repository.dart';
import 'journals_provider.dart';
import 'members_provider.dart';
import 'turn_provider.dart';

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

    final isShared = journal != null && journal.type != JournalType.personal;
    final isExchange = journal?.type == JournalType.exchange;
    final members = isShared
        ? (ref.watch(journalMembersProvider(journalId)).asData?.value ??
            const <JournalMember>[])
        : const <JournalMember>[];
    final turn = isExchange ? ref.watch(exchangeTurnProvider(journalId)) : null;

    // Resolves an entry's author to a display label (커플/교환 only).
    String authorLabel(String userId) {
      final m = members.where((m) => m.userId == userId).firstOrNull;
      if (m == null) return userId == 'me' ? '나' : '참여자';
      return m.isMe ? '나' : m.displayName;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _switchJournal(context, ref),
          child: Row(
            children: [
              if (journal != null) ...[
                Text(journal.displayIcon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(journal?.title ?? '일기장',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          if (journal != null)
            _JournalMenu(journal: journal),
        ],
      ),
      floatingActionButton: readOnly
          ? null
          : _buildFab(context, color, isExchange ? turn : null),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (readOnly)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _ArchivedBanner(),
              ),
            // Exchange journals: 차례 안내 + 이어쓰기/차례 넘기기.
            if (isExchange && !readOnly && turn != null)
              _TurnBanner(
                turn: turn,
                onContinue: turn.previousAuthorId != null
                    ? () => context.push(
                        '/write?journalId=$journalId&authorId=${turn.previousAuthorId}')
                    : null,
                onSkip: () => ref
                    .read(exchangeTurnControllerProvider)
                    .advance(journalId),
              ),
            // Shared journals (couple/exchange) show participants + invite.
            if (journal != null && journal.type != JournalType.personal)
              JournalMembersPanel(journal: journal),
            if (entries.isNotEmpty)
              _StatsStrip(stats: computeLifetimeStats(entries)),
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
                    child: EntryCard(
                      e,
                      authorName: isShared ? authorLabel(e.userId) : null,
                      onTap: () => context.push('/entry/${e.entryId}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  /// Opens a bottom sheet to jump to another active journal.
  Future<void> _switchJournal(BuildContext context, WidgetRef ref) async {
    final journals = (ref.read(journalsProvider).asData?.value ?? const [])
        .where((j) => !j.isArchived)
        .toList();
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('일기장 이동',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final j in journals)
              ListTile(
                leading:
                    Text(j.displayIcon, style: const TextStyle(fontSize: 20)),
                title: Text(j.title),
                subtitle: Text(j.type.label),
                trailing: j.journalId == journalId
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, j.journalId),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != journalId && context.mounted) {
      context.pushReplacement('/journal/$picked');
    }
  }

  /// FAB. For exchange journals it writes as the current turn holder and
  /// advances the turn; otherwise a plain new-entry button.
  Widget _buildFab(BuildContext context, Color color, ExchangeTurn? turn) {
    if (turn == null) {
      return FloatingActionButton.extended(
        backgroundColor: color,
        onPressed: () => context.push('/write?journalId=$journalId'),
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('기록', style: TextStyle(color: Colors.white)),
      );
    }
    final holder = turn.holder;
    final label = holder == null
        ? '기록'
        : (holder.isMe ? '내 차례 · 기록' : '${holder.displayName} 차례 · 기록');
    final extra =
        holder == null ? '' : '&authorId=${holder.userId}&advance=1';
    return FloatingActionButton.extended(
      backgroundColor: color,
      onPressed: () => context.push('/write?journalId=$journalId$extra'),
      icon: const Icon(Icons.edit, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

/// A compact one-line stats strip for this journal: record count, characters
/// written and the date of the first record.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.stats});
  final LifetimeStats stats;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parts = <String>[
      '기록 ${stats.totalEntries}개',
      '${stats.totalChars}자',
      if (stats.firstDate != null)
        '첫 기록 ${DateFormat('yyyy.M.d', locale).format(stats.firstDate!)}',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parts.join('  ·  '),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// 교환일기 차례 안내 배너. 상대가 오래 안 쓰면 이어쓰기/차례 넘기기를 연다.
class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.turn, this.onContinue, this.onSkip});
  final ExchangeTurn turn;
  final VoidCallback? onContinue;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final holder = turn.holder;
    final who = holder == null ? '' : (holder.isMe ? '내' : '${holder.displayName}님');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔁', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('지금은 $who 차례예요',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark)),
              ),
            ],
          ),
          if (turn.overdue && !turn.isMyTurn) ...[
            const SizedBox(height: 6),
            const Text('상대가 한동안 기록이 없어요. 이어서 쓰거나 차례를 넘길 수 있어요.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onContinue != null)
                  OutlinedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('이어쓰기'),
                  ),
                const SizedBox(width: 8),
                if (onSkip != null)
                  TextButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: const Text('차례 넘기기'),
                  ),
              ],
            ),
          ],
        ],
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
          case 'export':
            final messenger = ScaffoldMessenger.of(context);
            final entries =
                ref.read(entriesProvider).asData?.value ?? const [];
            final md = exportJournalMarkdown(journal, entries, DateTime.now());
            await Clipboard.setData(ClipboardData(text: md));
            final n = entries
                .where((e) => e.journalId == journal.journalId)
                .length;
            messenger.showSnackBar(
              SnackBar(
                content: Text(n == 0
                    ? '내보낼 기록이 없어요'
                    : '$n개 기록을 클립보드에 복사했어요'),
                duration: const Duration(seconds: 1),
              ),
            );
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
        const PopupMenuItem(value: 'export', child: Text('내보내기')),
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
