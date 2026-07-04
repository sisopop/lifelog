import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'photo_filters.dart';

/// Bottom sheet to choose (or clear) the colour filter for one photo.
///
/// Returns:
/// - a filter id from [kPhotoFilterChoices] when the user picks an effect,
/// - `''` (empty string) when the user picks "원본" (clear = no filter),
/// - `null` when the sheet is dismissed without a choice.
Future<String?> showFilterPickerSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('사진 효과',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FilterOption(
                  label: '원본',
                  matrix: null,
                  selected: current == null,
                  onTap: () => Navigator.pop(context, ''),
                ),
                for (final c in kPhotoFilterChoices)
                  _FilterOption(
                    label: c.label,
                    matrix: c.matrix,
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

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.matrix,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// null = 원본(필터 없이 원본 색상 미리보기).
  final List<double>? matrix;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A small colourful gradient swatch so each filter's effect is visible.
    Widget swatch = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7A59),
            Color(0xFF7C6FF0),
            Color(0xFF33C7B0),
          ],
        ),
      ),
    );
    final m = matrix;
    if (m != null) {
      swatch = ColorFiltered(colorFilter: ColorFilter.matrix(m), child: swatch);
    }
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
            Center(child: swatch),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
