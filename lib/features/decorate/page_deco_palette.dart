import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'sticker_catalog.dart';
import 'washi_tape_catalog.dart';

/// 페이지 꾸미기 에디터 하단의 요소 팔레트.
///
/// 사진·글자 추가 버튼, 마스킹테이프 색 띠, 스티커 카테고리 탭과 이모지 격자를
/// 보여준다. 상태는 갖지 않고 콜백으로만 위로 알린다([PageDecoPlayground]가 소유).
class DecoPalette extends StatelessWidget {
  const DecoPalette({
    super.key,
    required this.categoryIndex,
    required this.onCategory,
    required this.onAddPhoto,
    required this.onAddText,
    required this.onAddTape,
    required this.onAddSticker,
  });

  /// 현재 선택된 스티커 카테고리 인덱스.
  final int categoryIndex;
  final ValueChanged<int> onCategory;
  final VoidCallback onAddPhoto;
  final VoidCallback onAddText;

  /// 워시테이프 스타일 id를 올린다.
  final ValueChanged<String> onAddTape;

  /// 스티커 이모지를 올린다.
  final ValueChanged<String> onAddSticker;

  @override
  Widget build(BuildContext context) {
    final category = kStickerCatalog[categoryIndex];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: const Text('사진 추가'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onAddText,
                icon: const Icon(Icons.text_fields, size: 20),
                label: const Text('글자'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('테이프',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                for (final t in kWashiTapes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => onAddTape(t.id),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 46,
                        height: 24,
                        decoration: BoxDecoration(
                          color: t.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < kStickerCatalog.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(kStickerCatalog[i].label),
                      selected: i == categoryIndex,
                      onSelected: (_) => onCategory(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final emoji in category.stickers)
                InkWell(
                  onTap: () => onAddSticker(emoji),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
