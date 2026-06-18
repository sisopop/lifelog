import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/mood_chip.dart';
import '../../shared/widgets/photo.dart';
import '../../shared/models/journal.dart';
import '../entries/entries_provider.dart';
import '../journals/journal_repository.dart';
import '../journals/journals_provider.dart';
import '../journals/turn_provider.dart';

class WriteScreen extends ConsumerStatefulWidget {
  const WriteScreen({
    super.key,
    this.editId,
    this.journalId,
    this.authorId,
    this.advanceTurn = false,
  });

  /// When set, the screen edits an existing entry instead of creating one.
  final String? editId;

  /// Target journal for a new entry. Defaults to the user's default journal.
  final String? journalId;

  /// Who the new entry is attributed to (교환일기 차례 멤버). Defaults to 'me'.
  final String? authorId;

  /// After saving, advance the exchange-journal turn to the next member.
  final bool advanceTurn;

  @override
  ConsumerState<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends ConsumerState<WriteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _picker = ImagePicker();
  Mood? _mood;
  final List<String> _photoPaths = [];
  final List<String> _tags = [];
  DiaryEntry? _editing;
  bool _prefilled = false;

  /// Target journal for a new entry. Defaults to the route param / default
  /// journal, but can be changed via the journal selector at the top.
  String? _journalId;

  bool get _isEditing => widget.editId != null;

  /// Whether the user can change the target journal here. Editing keeps the
  /// entry's own journal; exchange-turn writes are pinned to keep turn order.
  bool get _canSwitchJournal => !_isEditing && !widget.advanceTurn;

  String get _targetJournalId =>
      _journalId ?? widget.journalId ?? JournalRepository.defaultJournalId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditing && !_prefilled) {
      final entries = ref.read(entriesProvider).asData?.value ?? const [];
      final entry = entries.where((e) => e.entryId == widget.editId).firstOrNull;
      if (entry != null) {
        _editing = entry;
        _titleCtrl.text = entry.title ?? '';
        _contentCtrl.text = entry.content;
        _mood = entry.mood;
        _photoPaths
          ..clear()
          ..addAll(entry.mediaUrls);
        _tags
          ..clear()
          ..addAll(entry.tags);
        _prefilled = true;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      // Encode as base64 data URLs so photos persist in the local DB and
      // render on every platform (web included). See shared/widgets/photo.dart.
      final encoded = <String>[];
      for (final x in picked) {
        final bytes = await x.readAsBytes();
        encoded.add('data:${_mimeFor(x.name)};base64,${base64Encode(bytes)}');
      }
      if (mounted) setState(() => _photoPaths.addAll(encoded));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러오지 못했어요')),
        );
      }
    }
  }

  String _mimeFor(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.gif')) return 'image/gif';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _addTag() async {
    final ctrl = TextEditingController();
    final tag = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('태그 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: '예: 여행, 가족'),
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
  }

  Future<void> _save({required EntryVisibility visibility}) async {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }
    final now = DateTime.now();
    final notifier = ref.read(entriesProvider.notifier);
    if (_isEditing && _editing != null) {
      // Edit: keep id/createdAt; editEntry regenerates the AI summary.
      await notifier.editEntry(
        _editing!.copyWith(
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          mood: _mood,
          visibility: visibility,
          mediaUrls: List.of(_photoPaths),
          tags: List.of(_tags),
        ),
      );
    } else {
      final journalId = _targetJournalId;
      await notifier.add(
        DiaryEntry(
          entryId: now.microsecondsSinceEpoch.toString(),
          userId: widget.authorId ?? 'me',
          journalId: journalId,
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          mood: _mood,
          visibility: visibility,
          aiStatus: AiStatus.pending, // summary generated async (see TECH_DESIGN.md)
          mediaUrls: List.of(_photoPaths),
          tags: List.of(_tags),
          createdAt: now,
          updatedAt: now,
        ),
      );
      // 교환일기: 기록 후 다음 멤버에게 차례를 넘긴다.
      if (widget.advanceTurn) {
        await ref.read(exchangeTurnControllerProvider).advance(journalId);
      }
    }
    if (mounted) context.pop();
  }

  /// Bottom sheet to change which journal this new entry is saved into.
  Future<void> _pickJournal(List<Journal> journals) async {
    final active = journals.where((j) => !j.isArchived).toList();
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
                child: Text('어느 일기장에 쓸까요?',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final j in active)
              ListTile(
                leading:
                    Text(j.displayIcon, style: const TextStyle(fontSize: 20)),
                title: Text(j.title),
                subtitle: Text(j.type.label),
                trailing: j.journalId == _targetJournalId
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, j.journalId),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != _targetJournalId) {
      setState(() => _journalId = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shared journals (커플/교환) record entries as shared by default;
    // personal journals keep the private-first flow.
    final journals =
        ref.watch(journalsProvider).asData?.value ?? const <Journal>[];
    final jid = _targetJournalId;
    final journal = journals.where((j) => j.journalId == jid).firstOrNull;
    final shared = journal != null && journal.type != JournalType.personal;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '기록 수정' : '새 기록'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Shows (and, for new entries, lets you change) the target journal.
          if (!_isEditing && journal != null) ...[
            _JournalSelector(
              journal: journal,
              canSwitch: _canSwitchJournal,
              onTap: _canSwitchJournal
                  ? () => _pickJournal(journals)
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: '제목 (선택)',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text('오늘의 감정', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: Mood.values
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: MoodChip(m,
                            selected: _mood == m,
                            onTap: () => setState(() => _mood = m)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _contentCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '오늘 어떤 하루였나요?',
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
            ),
          ),
          if (_photoPaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photoPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PhotoView(_photoPaths[i], width: 84, height: 84),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _photoPaths.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _tags
                  .map((t) => Chip(
                        label: Text('#$t'),
                        onDeleted: () => setState(() => _tags.remove(t)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _AttachButton(Icons.photo_outlined, '사진', _pickPhotos),
              const _AttachButton(Icons.mic_none, '음성', null),
              const _AttachButton(Icons.place_outlined, '위치', null),
              _AttachButton(Icons.tag, '태그', _addTag),
            ],
          ),
          const SizedBox(height: 28),
          if (_isEditing)
            ElevatedButton(
              onPressed: () => _save(
                visibility: _editing?.visibility ?? EntryVisibility.private,
              ),
              child: const Text('수정 저장'),
            )
          else if (shared) ...[
            // 커플/교환 일기장은 멤버와 함께 보는 공동 기록이 기본.
            ElevatedButton(
              onPressed: () => _save(visibility: EntryVisibility.link),
              child: const Text('함께 저장'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => _save(visibility: EntryVisibility.private),
              child: const Text('비공개 저장'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _save(visibility: EntryVisibility.link),
              child: const Text('공유하며 저장',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header chip showing the target journal. Tappable (with a ▾) when the
/// journal can be changed; otherwise a static label.
class _JournalSelector extends StatelessWidget {
  const _JournalSelector({
    required this.journal,
    required this.canSwitch,
    this.onTap,
  });
  final Journal journal;
  final bool canSwitch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(journal.coverColor);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(journal.displayIcon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('일기장 · ',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Flexible(
              child: Text(
                journal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            if (canSwitch) ...[
              const Spacer(),
              const Text('변경',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.textSecondary),
      label: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
