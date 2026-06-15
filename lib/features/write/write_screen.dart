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
import '../entries/entries_provider.dart';

class WriteScreen extends ConsumerStatefulWidget {
  const WriteScreen({super.key, this.editId});

  /// When set, the screen edits an existing entry instead of creating one.
  final String? editId;

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

  bool get _isEditing => widget.editId != null;

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
      // Edit: keep id/createdAt, regenerate AI summary, refresh.
      await notifier.saveEntry(
        _editing!.copyWith(
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          mood: _mood,
          visibility: visibility,
          aiStatus: AiStatus.done,
          aiSummary: _editing!.aiSummary,
          mediaUrls: List.of(_photoPaths),
          tags: List.of(_tags),
        ),
      );
    } else {
      await notifier.add(
        DiaryEntry(
          entryId: now.microsecondsSinceEpoch.toString(),
          userId: 'me',
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
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '기록 수정' : '새 기록'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
          Row(
            children: Mood.values
                .map((m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: MoodChip(m,
                          selected: _mood == m,
                          onTap: () => setState(() => _mood = m)),
                    ))
                .toList(),
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
          ElevatedButton(
            onPressed: () => _save(
              visibility: _editing?.visibility ?? EntryVisibility.private,
            ),
            child: Text(_isEditing ? '수정 저장' : '비공개 저장'),
          ),
          if (!_isEditing) ...[
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
