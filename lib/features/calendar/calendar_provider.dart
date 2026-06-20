import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns [from] shifted by [delta] months, keeping the same day-of-month
/// where possible and clamping to the target month's last day (so Jan 31 →
/// Feb 28/29). Year rolls over naturally.
DateTime shiftMonth(DateTime from, int delta) {
  final firstOfTarget = DateTime(from.year, from.month + delta, 1);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  final day = from.day > lastDay ? lastDay : from.day;
  return DateTime(firstOfTarget.year, firstOfTarget.month, day);
}

/// Holds the selected date for the dedicated 캘린더 screen.
/// The month is derived from the selected date; navigating months keeps
/// the same day-of-month when possible (clamped to the month's last day).
class CalendarDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Select a day within the currently shown month.
  void select(int day) {
    state = DateTime(state.year, state.month, day);
  }

  /// Jump to the same day in the previous month (clamped to its last day).
  void previousMonth() => _shiftMonth(-1);

  /// Jump to the same day in the next month (clamped to its last day).
  void nextMonth() => _shiftMonth(1);

  void _shiftMonth(int delta) => state = shiftMonth(state, delta);
}

final calendarDateProvider =
    NotifierProvider<CalendarDateNotifier, DateTime>(CalendarDateNotifier.new);
