import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../entries/entries_provider.dart';
import '../stats/stats_provider.dart';
import '../stats/streak.dart';
import 'journal_activity.dart';

/// Home strip showing the last 7 days and whether each was journaled, with
/// today highlighted. A gentle at-a-glance nudge to keep the habit going.
class WeeklyStripSection extends ConsumerWidget {
  const WeeklyStripSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dots = ref.watch(weeklyProgressProvider);
    final recorded = dots.where((d) => d.done).length;
    final streakInfo = ref.watch(homeStreakInfoProvider);
    final streak = streakInfo.current;
    final monthCount = ref.watch(thisMonthCountProvider);
    final weekCount = ref.watch(thisWeekCountProvider);
    final allEntries = ref.watch(entriesProvider).asData?.value ?? const [];
    final weekMood = weekDominantMood(allEntries, DateTime.now());
    // Encourage beating the record only when the best run is meaningfully
    // longer than the current one.
    final showBest = streakInfo.longest >= 2 && streakInfo.longest > streak;

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
              if (streak > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('🔥 $streak일 연속',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                ),
              ],
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
                _DayDotView(
                  dot: dots[i],
                  isToday: i == dots.length - 1,
                  onTap: dots[i].done
                      ? () => context.push('/day/${_iso(dots[i].date)}')
                      : null,
                ),
            ],
          ),
          if (weekCount > 0) ...[
            const SizedBox(height: 12),
            Text('이번 주 $weekCount개 기록했어요',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (weekMood != null) ...[
            SizedBox(height: weekCount > 0 ? 6 : 12),
            Text('${weekMood.emoji} 이번 주는 주로 ${weekMood.label}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (monthCount > 0) ...[
            SizedBox(height: weekCount > 0 ? 6 : 12),
            Text('이번 달 $monthCount개 기록했어요',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (showBest) ...[
            const SizedBox(height: 6),
            Text('🏆 최고 기록은 ${streakInfo.longest}일 연속이에요',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _DayDotView extends StatelessWidget {
  const _DayDotView({required this.dot, required this.isToday, this.onTap});
  final DayDot dot;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
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
        ),
      ),
    );
  }
}
