import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/mood_chip.dart';
import 'text_stats.dart';

/// "오늘의 감정" picker: a labelled horizontal row of [MoodChip]s plus a gentle
/// [moodReminder] nudge shown when a long entry has no mood yet. Standalone so
/// the write screen stays within its line budget.
class MoodField extends StatelessWidget {
  const MoodField({
    super.key,
    required this.value,
    required this.contentText,
    required this.onChanged,
  });

  final Mood? value;
  final String contentText;
  final ValueChanged<Mood?> onChanged;

  @override
  Widget build(BuildContext context) {
    final nudge = moodReminder(contentText, value != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('오늘의 감정',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: Mood.values
                .map((m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: MoodChip(m,
                          selected: value == m,
                          onTap: () => onChanged(toggledMood(value, m))),
                    ))
                .toList(),
          ),
        ),
        if (nudge != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(nudge,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
      ],
    );
  }
}
