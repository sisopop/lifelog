import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/entry_card.dart';
import '../../shared/widgets/month_calendar.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import '../review/day_entries.dart';
import '../stats/stats_provider.dart';
import 'calendar_provider.dart';

/// A dedicated calendar screen: browse months, see which days have records
/// (colored by that day's dominant mood), and tap a day to see its records.
/// Tapping a record opens its detail.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(calendarDateProvider);
    final ctrl = ref.read(calendarDateProvider.notifier);
    final all = ref.watch(entriesProvider).asData?.value ?? const [];
    final journals = ref.watch(journalsProvider).asData?.value ?? const [];
    final journalMap = {for (final j in journals) j.journalId: j};

    final recordedDays = recordedDaysOfMonth(all, selected.year, selected.month);
    final dayMoods = dominantMoodByDay(all, selected.year, selected.month);
    final dayEntries = entriesOfDay(all, selected);
    final monthCount = monthEntryCount(all, selected.year, selected.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: '이전 달',
                onPressed: ctrl.previousMonth,
              ),
              Expanded(
                child: Text('${selected.year}년 ${selected.month}월',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: '다음 달',
                onPressed: ctrl.nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          MonthCalendar(
            year: selected.year,
            month: selected.month,
            recordedDays: recordedDays,
            dayMoods: dayMoods,
            selectedDay: selected.day,
            onDayTap: ctrl.select,
          ),
          if (monthCount > 0) ...[
            const SizedBox(height: 12),
            Text('🗓️ 이번 달 ${recordedDays.length}일 · 기록 $monthCount개',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 20),
          Text(
              dayEntries.isEmpty
                  ? '${selected.month}월 ${selected.day}일 기록'
                  : '${selected.month}월 ${selected.day}일 기록 · ${dayEntries.length}개',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (dayEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('이 날의 기록이 없어요',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            for (final e in dayEntries) ...[
              EntryCard(
                e,
                journalName: journalMap[e.journalId]?.title,
                journalIcon: journalMap[e.journalId]?.displayIcon,
                onTap: () => context.push('/entry/${e.entryId}'),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
