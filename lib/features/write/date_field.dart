import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../home/journal_activity.dart';

/// Tappable date row on the write screen. Shows the entry's calendar day and
/// opens a date picker so past diaries can be back-dated.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(date);
    final rel = backdatedDayLabel(date, DateTime.now());
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.event, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
            if (rel != null) ...[
              const SizedBox(width: 6),
              Text('· $rel',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textHint)),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.edit, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
