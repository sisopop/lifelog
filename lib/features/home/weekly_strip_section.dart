import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../stats/stats_provider.dart';

/// Home strip showing the last 7 days and whether each was journaled, with
/// today highlighted. A gentle at-a-glance nudge to keep the habit going.
class WeeklyStripSection extends ConsumerWidget {
  const WeeklyStripSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dots = ref.watch(weeklyProgressProvider);
    final recorded = dots.where((d) => d.done).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('이번 주 기록',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('$recorded / 7일',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < dots.length; i++)
                _DayDotView(dot: dots[i], isToday: i == dots.length - 1),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDotView extends StatelessWidget {
  const _DayDotView({required this.dot, required this.isToday});
  final DayDot dot;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dot.done ? AppColors.primary : AppColors.primarySoft,
            border: isToday
                ? Border.all(color: AppColors.primaryDark, width: 2)
                : null,
          ),
          child: dot.done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 6),
        Text(dot.label,
            style: TextStyle(
                fontSize: 11,
                color: isToday ? AppColors.primaryDark : AppColors.textHint,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
  }
}
