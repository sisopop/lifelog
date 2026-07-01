// 페이지 꾸미기 에디터의 속지(배경) 선택 바.
//
// 무늬(PaperStyle: 무지/줄/모눈/도트)와 바탕색(기본 크림 + 파스텔 팔레트)을 고른다.
// 캔버스 상태는 상위(PageDecoPlayground)가 들고, 이 위젯은 현재 값과 콜백만 받는다.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'page_canvas.dart';
import 'paper_color_catalog.dart';

const _paperLabels = {
  PaperStyle.plain: '무지',
  PaperStyle.lined: '줄',
  PaperStyle.grid: '모눈',
  PaperStyle.dotted: '도트',
};

/// 속지 무늬·바탕색을 고르는 두 줄짜리 선택 바.
class PaperSelector extends StatelessWidget {
  const PaperSelector({
    super.key,
    required this.paper,
    required this.paperColorValue,
    required this.onPaperChanged,
    required this.onColorChanged,
  });

  final PaperStyle paper;
  final int? paperColorValue;
  final ValueChanged<PaperStyle> onPaperChanged;

  /// null이면 기본 크림.
  final ValueChanged<int?> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('속지',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              for (final style in PaperStyle.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_paperLabels[style]!),
                    selected: paper == style,
                    onSelected: (_) => onPaperChanged(style),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('바탕색',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                _dot(null, kPaperDefaultCream, '기본'),
                for (final c in kPaperColors) _dot(c.toARGB32(), c, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 속지 바탕색 스와치 한 개. [value]가 null이면 기본(크림). 선택되면 테두리 강조.
  Widget _dot(int? value, Color swatch, String? label) {
    final selected = paperColorValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onColorChanged(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: swatch,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: label != null
              ? const Text('기본',
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary))
              : (selected
                  ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                  : null),
        ),
      ),
    );
  }
}
