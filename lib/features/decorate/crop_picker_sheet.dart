import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'photo_crops.dart';

/// Bottom sheet to choose (or clear) the crop position for one photo.
///
/// Returns:
/// - a crop id from [kPhotoCropChoices] when the user picks a position,
/// - `''` (empty string) when the user picks "중앙" (clear = centre crop),
/// - `null` when the sheet is dismissed without a choice.
Future<String?> showCropPickerSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('크롭 위치',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('비율이 다른 사진에서 어느 부분을 남길지 골라요',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CropOption(
                  label: '중앙',
                  alignment: Alignment.center,
                  selected: current == null,
                  onTap: () => Navigator.pop(context, ''),
                ),
                for (final c in kPhotoCropChoices)
                  _CropOption(
                    label: c.label,
                    alignment: c.alignment,
                    selected: current == c.id,
                    onTap: () => Navigator.pop(context, c.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _CropOption extends StatelessWidget {
  const _CropOption({
    required this.label,
    required this.alignment,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Alignment alignment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A 44×44 frame with a smaller "kept region" tile pushed toward [alignment].
    final swatch = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textHint),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: alignment,
        child: Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            border: Border.all(color: AppColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2),
        ),
        child: Column(
          children: [
            swatch,
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
