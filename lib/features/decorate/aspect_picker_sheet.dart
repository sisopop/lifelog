import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'photo_aspects.dart';

/// Bottom sheet to choose (or clear) the display ratio for one photo.
///
/// Returns:
/// - an aspect id from [kPhotoAspectChoices] when the user picks a ratio,
/// - `''` (empty string) when the user picks "원본" (clear = natural ratio),
/// - `null` when the sheet is dismissed without a choice.
Future<String?> showAspectPickerSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('사진 비율',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AspectOption(
                  label: '원본',
                  ratio: null,
                  selected: current == null,
                  onTap: () => Navigator.pop(context, ''),
                ),
                for (final c in kPhotoAspectChoices)
                  _AspectOption(
                    label: c.label,
                    ratio: c.ratio,
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

class _AspectOption extends StatelessWidget {
  const _AspectOption({
    required this.label,
    required this.ratio,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// null = 원본(자유 크기 미리보기).
  final double? ratio;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A small swatch drawn at the chosen ratio (원본 uses a dashed-ish free box).
    final swatch = SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: AspectRatio(
          aspectRatio: ratio ?? 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: ratio == null
                  ? Colors.transparent
                  : AppColors.primarySoft,
              border: Border.all(
                color: ratio == null ? AppColors.textHint : AppColors.primary,
                width: ratio == null ? 1 : 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ratio == null
                ? const Icon(Icons.crop_free_rounded,
                    size: 18, color: AppColors.textHint)
                : null,
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
