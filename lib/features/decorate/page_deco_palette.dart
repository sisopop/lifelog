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
    this.onAddTextBox,
    this.showPhoto = true,
    this.showText = true,
    this.showTextBox = false,
    this.showTape = true,
    this.showSticker = true,
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

  /// 사진 추가 버튼을 보일지("사진" 탭 전용).
  final bool showPhoto;

  /// 빈 텍스트박스(직접 입력하는 상자)를 올린다. null이면 버튼을 감춘다.
  final VoidCallback? onAddTextBox;

  /// 글자 넣기 버튼을 보일지("텍스트" 탭 전용).
  final bool showText;

  /// 텍스트박스 추가 버튼을 보일지("텍스트" 탭 전용). onAddTextBox가 있어야 뜬다.
  final bool showTextBox;

  /// 마스킹테이프 색 띠를 보일지("테이프" 탭 전용).
  final bool showTape;

  /// 스티커 카테고리+이모지 격자를 보일지("스티커" 탭 전용).
  final bool showSticker;

  /// 텍스트박스 버튼을 그릴 수 있는지(보이기 플래그 + 콜백 모두 있을 때).
  bool get _canBox => showTextBox && onAddTextBox != null;

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
          if (showPhoto || showText || _canBox)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showPhoto)
                  OutlinedButton.icon(
                    onPressed: onAddPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 20),
                    label: const Text('사진 추가'),
                  ),
                if (showText)
                  OutlinedButton.icon(
                    onPressed: onAddText,
                    icon: const Icon(Icons.text_fields, size: 20),
                    label: const Text('글자 넣기'),
                  ),
                if (_canBox)
                  OutlinedButton.icon(
                    onPressed: onAddTextBox,
                    icon: const Icon(Icons.crop_square, size: 20),
                    label: const Text('텍스트박스'),
                  ),
              ],
            ),
          if (showTape) ...[
            if (showPhoto || showText || _canBox) const SizedBox(height: 8),
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
          ],
          if (showSticker) ...[
            if (showPhoto || showTape) const SizedBox(height: 8),
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
        ],
      ),
    );
  }
}
