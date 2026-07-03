import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'frame_catalog.dart';

/// Bottom sheet to choose (or clear) a decorative frame for one photo.
///
/// Returns:
/// - a frame id from [kPhotoFrames] when the user picks a style,
/// - `''` (empty string) when the user explicitly picks "없음" (clear),
/// - `null` when the sheet is dismissed without a choice.
Future<String?> showFramePickerSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('사진 프레임',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FrameOption(
                  label: '없음',
                  selected: current == null,
                  onTap: () => Navigator.pop(context, ''),
                  swatch: const Icon(Icons.not_interested_rounded,
                      color: AppColors.textHint),
                ),
                for (final f in kPhotoFrames)
                  _FrameOption(
                    label: f.label,
                    selected: current == f.id,
                    onTap: () => Navigator.pop(context, f.id),
                    swatch: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: f.borderColor, width: f.borderWidth / 2),
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

class _FrameOption extends StatelessWidget {
  const _FrameOption({
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
