import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/photo.dart';
import 'content_flow.dart';

/// 본문 글 흐름 사이사이에 "전체 폭 사진 블록"을 끼우는 편집기.
///
/// [content](순수 텍스트)는 건드리지 않고, 사진의 *끼움 위치*([InlinePhoto])만
/// 편집한다. 문단(빈 줄 경계) 사이마다 틈을 보여 주고, 각 틈에 사진을 넣거나 뺄 수
/// 있다. "완료"를 누르면 편집된 목록을, 뒤로 가면 null(취소)을 돌려준다.
class InlinePhotoEditor extends StatefulWidget {
  const InlinePhotoEditor({
    super.key,
    required this.content,
    this.initial = const [],
  });

  final String content;
  final List<InlinePhoto> initial;

  @override
  State<InlinePhotoEditor> createState() => _InlinePhotoEditorState();
}

class _InlinePhotoEditorState extends State<InlinePhotoEditor> {
  final _picker = ImagePicker();
  late List<InlinePhoto> _photos;
  late List<String> _paragraphs;

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.initial);
    _paragraphs = splitContentParagraphs(widget.content);
  }

  /// 특정 틈(문단 [pos]개 뒤)에 넣힌 사진들 — 넣은 순서 유지.
  List<InlinePhoto> _at(int pos) =>
      _photos.where((p) => p.afterParagraph == pos).toList();

  Future<void> _addAt(int pos) async {
    try {
      final x = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1600);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final url =
          'data:${imageMimeForName(x.name)};base64,${base64Encode(bytes)}';
      if (mounted) {
        setState(() =>
            _photos.add(InlinePhoto(path: url, afterParagraph: pos)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러오지 못했어요')),
        );
      }
    }
  }

  void _remove(InlinePhoto photo) => setState(() => _photos.remove(photo));

  @override
  Widget build(BuildContext context) {
    final n = _paragraphs.length;
    final rows = <Widget>[];
    for (var pos = 0; pos <= n; pos++) {
      rows.add(_GapRow(
        label: _gapLabel(pos, n),
        photos: _at(pos),
        onAdd: () => _addAt(pos),
        onRemove: _remove,
      ));
      if (pos < n) rows.add(_ParagraphCard(_paragraphs[pos]));
    }
    if (n == 0 && _photos.isEmpty) {
      rows.add(const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Text('본문을 먼저 쓰면 문단 사이에 사진을 끼울 수 있어요.',
            style: TextStyle(color: AppColors.textHint)),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('사진 끼우기'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_photos),
            child: const Text('완료'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: rows,
      ),
    );
  }

  String _gapLabel(int pos, int n) {
    if (pos == 0) return '맨 위';
    if (pos == n) return '맨 아래';
    return '$pos번째 문단 뒤';
  }
}

/// 편집기를 띄워 끼움 사진을 고르게 하고 저장용 JSON을 돌려준다.
/// 취소(뒤로가기)면 [current]를 그대로, 사진을 다 빼면 null을 준다.
Future<String?> editInlinePhotosFlow(
  BuildContext context, {
  required String content,
  required String? current,
}) async {
  final result = await Navigator.of(context).push<List<InlinePhoto>>(
    MaterialPageRoute(
      builder: (_) => InlinePhotoEditor(
        content: content,
        initial: decodeInlinePhotos(current),
      ),
    ),
  );
  if (result == null) return current; // 취소 → 그대로 둔다
  return result.isEmpty ? null : encodeInlinePhotos(result);
}

/// 작성 화면에 놓는 "본문 사이 사진" 진입 타일(끼운 장수를 요약해 보여 준다).
class InlinePhotoTile extends StatelessWidget {
  const InlinePhotoTile({
    super.key,
    required this.flowPhotos,
    required this.onEdit,
  });

  final String? flowPhotos;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final count = decodeInlinePhotos(flowPhotos).length;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.photo_size_select_actual_outlined,
                color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('본문 사이 사진',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? '문단 사이에 전체 폭 사진을 끼워 보세요'
                        : '사진 $count장 끼움',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({
    required this.label,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<InlinePhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<InlinePhoto> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in photos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PhotoView(p.path, height: 160, iconSize: 40),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () => onRemove(p),
                    child: const CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: Text('$label 사진 넣기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.divider),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParagraphCard extends StatelessWidget {
  const _ParagraphCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
      ),
    );
  }
}
