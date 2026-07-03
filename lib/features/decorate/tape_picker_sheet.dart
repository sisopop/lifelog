import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'washi_tape_catalog.dart';

/// Bottom sheet to choose (or clear) a decorative washi tape for one photo.
///
/// Returns:
/// - a tape id from [kWashiTapes] when the user picks a color,
/// - `''` (empty string) when the user explicitly picks "없음" (clear),
/// - `null` when the sheet is dismissed without a choice.
Future<String?> showTapePickerSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('사진 테이프',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _TapeOption(
                  label: '없음',
                  selected: current == null,
                  onTap: () => Navigator.pop(context, ''),
                  swatch: const Icon(Icons.not_interested_rounded,
                      color: AppColors.textHint),
                ),
                for (final t in kWashiTapes)
                  _TapeOption(
                    label: t.label,
                    selected: current == t.id,
                    onTap: () => Navigator.pop(context, t.id),
                    swatch: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: t.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _TapeOption extends StatelessWidget {
  const _TapeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.swatch,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget swatch;

  @override
  Widget build(BuildContext context) {
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
