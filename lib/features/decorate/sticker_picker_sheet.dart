import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'sticker_catalog.dart';

/// Bottom sheet to choose (or clear) a sticker emoji for one photo.
///
/// Returns:
/// - an emoji from [kStickerCatalog] when the user picks one,
/// - `''` (empty string) when the user explicitly picks "없음" (clear),
/// - `null` when the sheet is dismissed without a choice.
Future<String?> showStickerPickerSheet(BuildContext context,
    {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('사진 스티커',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _StickerOption(
                          selected: current == null,
                          onTap: () => Navigator.pop(context, ''),
                          child: const Icon(Icons.not_interested_rounded,
                              color: AppColors.textHint, size: 20),
                        ),
                      ],
                    ),
                    for (final category in kStickerCatalog) ...[
                      const SizedBox(height: 14),
                      Text(category.label,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final emoji in category.stickers)
                            _StickerOption(
                              selected: current == emoji,
                              onTap: () => Navigator.pop(context, emoji),
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StickerOption extends StatelessWidget {
  const _StickerOption({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2),
        ),
        child: child,
      ),
    );
  }
}
