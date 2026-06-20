import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import 'entry_clipboard.dart';
import '../../shared/models/journal_member.dart';
import '../../shared/widgets/photo.dart';
import '../entries/entries_provider.dart';
import '../journals/members_provider.dart';
import '../journals/members_repository.dart';
import '../settings/reading_text_scale.dart';
import 'entry_neighbors.dart';

class EntryDetailScreen extends ConsumerStatefulWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReply(DiaryEntry parent) async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    await ref
        .read(entriesProvider.notifier)
        .addReply(parent: parent, content: text);
    if (mounted) {
      _replyCtrl.clear();
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final entry = entries.where((e) => e.entryId == widget.entryId).firstOrNull;

    if (entry == null) {
      return const Scaffold(body: Center(child: Text('기록을 찾을 수 없습니다')));
    }

    final replies = entries
        .where((e) => e.replyToEntryId == widget.entryId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMMEEEEd(locale).format(entry.createdAt);
    final scale = ref.watch(readingTextScaleProvider);

    // Author label for shared journals (멤버가 2명 이상일 때만 표시).
    final members =
        ref.watch(journalMembersProvider(entry.journalId)).asData?.value ??
            const <JournalMember>[];
    final author = members.where((m) => m.userId == entry.userId).firstOrNull;
    final authorName = members.length < 2
        ? null
        : (author == null
            ? (entry.userId == MembersRepository.meUserId ? '나' : '참여자')
            : (author.isMe ? '나' : author.displayName));

    return Scaffold(
      appBar: AppBar(actions: [_favoriteButton(entry), _menu(context, entry)]),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _header(entry, date, authorName),
                const SizedBox(height: 20),
                if (entry.mediaUrls.isNotEmpty) ...[
                  _gallery(entry),
                  const SizedBox(height: 20),
                ],
                Text(entry.content,
                    style: TextStyle(fontSize: 16 * scale, height: 1.6)),
                const SizedBox(height: 24),
                _aiSummary(entry),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: entry.tags
                      .map((t) => ActionChip(
                            label: Text('#$t'),
                            onPressed: () => context.push(
                                Uri(path: '/tag', queryParameters: {'t': t})
                                    .toString()),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => context.push('/entry/${widget.entryId}/share'),
                  icon: const Icon(Icons.share),
                  label: const Text('공유하기'),
                ),
                const SizedBox(height: 12),
                _neighborNav(entries),
                const Divider(height: 40),
                Text('답장 ${replies.length}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (replies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('아직 답장이 없어요. 첫 답장을 남겨보세요.',
                        style: TextStyle(color: AppColors.textHint)),
                  )
                else
                  ...replies.map((r) => _ReplyBubble(
                        reply: r,
                        locale: locale,
                        journalId: entry.journalId,
                      )),
              ],
            ),
          ),
          _composer(entry),
        ],
      ),
    );
  }

  Widget _favoriteButton(DiaryEntry entry) {
    return IconButton(
      icon: Icon(entry.isFavorite ? Icons.star : Icons.star_border,
          color: entry.isFavorite ? Colors.amber : null),
      tooltip: entry.isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
      onPressed: () =>
          ref.read(entriesProvider.notifier).toggleFavorite(entry),
    );
  }

  /// "← 이전 기록 / 다음 기록 →" jump within the same journal. Uses
  /// pushReplacement so the back button still returns to the list.
  Widget _neighborNav(List<DiaryEntry> entries) {
    final nav = adjacentEntries(entries, widget.entryId);
    if (nav.previous == null && nav.next == null) return const SizedBox.shrink();

    Widget button(DiaryEntry? target, {required bool isPrev}) {
      final onPressed = target == null
          ? null
          : () => context.pushReplacement('/entry/${target.entryId}');
      final style = TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        disabledForegroundColor: AppColors.textHint.withValues(alpha: 0.4),
      );
      const arrowSize = 20.0;
      // Arrow leads on "이전 기록", trails on "다음 기록".
      return isPrev
          ? TextButton.icon(
              onPressed: onPressed,
              style: style,
              icon: const Icon(Icons.chevron_left, size: arrowSize),
              label: const Text('이전 기록'),
            )
          : TextButton.icon(
              onPressed: onPressed,
              style: style,
              icon: const Text('다음 기록'),
              label: const Icon(Icons.chevron_right, size: arrowSize),
            );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        button(nav.previous, isPrev: true),
        button(nav.next, isPrev: false),
      ],
    );
  }

  Widget _menu(BuildContext context, DiaryEntry entry) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      onSelected: (v) async {
        if (v == 'edit') {
          context.push('/entry/${widget.entryId}/edit');
        } else if (v == 'copy') {
          await Clipboard.setData(
              ClipboardData(text: entryClipboardText(entry)));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('기록을 클립보드에 복사했어요')),
            );
          }
        } else if (v == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('기록 삭제'),
              content: const Text('이 기록을 삭제할까요? 되돌릴 수 없어요.'),
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
          if (ok == true) {
            await ref.read(entriesProvider.notifier).delete(widget.entryId);
            if (context.mounted) context.pop();
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('수정')),
        PopupMenuItem(value: 'copy', child: Text('복사')),
        PopupMenuItem(value: 'delete', child: Text('삭제')),
      ],
    );
  }

  Widget _header(DiaryEntry entry, String date, String? authorName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (entry.mood != null) ...[
              Text(entry.mood!.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(entry.title ?? '제목 없음',
                  style:
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            Text(entry.visibility.icon, style: const TextStyle(fontSize: 18)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (authorName != null) ...[
              CircleAvatar(
                radius: 9,
                backgroundColor: AppColors.primarySoft,
                child: Text(authorName.characters.first,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 5),
              Text('$authorName · ',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600)),
            ],
            Text(
                (entry.location ?? '').trim().isEmpty
                    ? date
                    : '$date · ${entry.location!.trim()}',
                style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _gallery(DiaryEntry entry) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entry.mediaUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: PhotoView(entry.mediaUrls[i], width: 260, height: 200, iconSize: 40),
        ),
      ),
    );
  }

  Widget _aiSummary(DiaryEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(entry.aiSummary ?? 'AI 요약을 생성하고 있어요...',
                style: const TextStyle(color: AppColors.textPrimary, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _composer(DiaryEntry entry) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendReply(entry),
                decoration: const InputDecoration(
                  hintText: '답장 남기기…',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: AppColors.primary),
              onPressed: _sending ? null : () => _sendReply(entry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBubble extends ConsumerWidget {
  const _ReplyBubble({
    required this.reply,
    required this.locale,
    required this.journalId,
  });
  final DiaryEntry reply;
  final String locale;
  final String journalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat.MMMd(locale).add_jm().format(reply.createdAt);
    final members =
        ref.watch(journalMembersProvider(journalId)).asData?.value ??
            const <JournalMember>[];
    final author =
        members.where((m) => m.userId == reply.userId).firstOrNull;
    final name = author == null
        ? (reply.userId == MembersRepository.meUserId ? '나' : '참여자')
        : (author.isMe ? '나' : author.displayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  name.characters.first,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(reply.content, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 6),
          Text(time,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
