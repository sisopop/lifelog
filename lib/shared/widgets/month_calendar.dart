import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/enums.dart';

/// Maps a mood to its calendar/legend color.
Color moodColor(Mood m) => switch (m) {
      Mood.good => AppColors.moodGood,
      Mood.neutral => AppColors.moodNeutral,
      Mood.hard => AppColors.moodHard,
    };

/// A compact month grid (일~토) highlighting days that have a record,
/// colored by that day's dominant mood (falls back to primary when no mood).
/// Optionally rings a [selectedDay] and reports taps via [onDayTap].
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.recordedDays,
    required this.dayMoods,
    this.onDayTap,
    this.selectedDay,
  });

  final int year;
  final int month;
  final Set<int> recordedDays;
  final Map<int, Mood> dayMoods;
  final void Function(int day)? onDayTap;
  final int? selectedDay;

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Sunday-first: leading blanks before day 1.
    final leading = DateTime(year, month, 1).weekday % 7;
    final cells = <Widget>[
      for (final w in _weekdayLabels)
        Center(
          child: Text(w,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _DayCell(
          d,
          recordedDays.contains(d),
          mood: dayMoods[d],
          selected: selectedDay == d,
          onTap: onDayTap == null ? null : () => onDayTap!(d),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: cells,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell(this.day, this.recorded,
      {this.mood, this.selected = false, this.onTap});
  final int day;
  final bool recorded;
  final Mood? mood;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Mood color when known (pastel → dark text), else primary, else plain.
    final Color bg = !recorded
        ? AppColors.background
        : (mood != null ? moodColor(mood!) : AppColors.primary);
    final Color fg = !recorded
        ? AppColors.textSecondary
        : (mood != null ? AppColors.textPrimary : Colors.white);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: AppColors.primaryDark, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 12,
            fontWeight: recorded || selected ? FontWeight.w700 : FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}
