import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/enums.dart';

class MoodChip extends StatelessWidget {
  const MoodChip(this.mood, {super.key, this.selected = false, this.onTap});

  final Mood mood;
  final bool selected;
  final VoidCallback? onTap;

  Color get _color => switch (mood) {
        Mood.good => AppColors.moodGood,
        Mood.neutral => AppColors.moodNeutral,
        Mood.hard => AppColors.moodHard,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _color.withValues(alpha: 0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? _color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
