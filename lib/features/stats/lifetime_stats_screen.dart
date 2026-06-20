import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../entries/entries_provider.dart';
import '../journals/journals_provider.dart';
import 'lifetime_stats.dart';

/// "내 기록 요약" — a whole-history snapshot reached from settings.
class LifetimeStatsScreen extends ConsumerWidget {
  const LifetimeStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final journals = (ref.watch(journalsProvider).asData?.value ?? const [])
        .where((j) => !j.isArchived)
        .length;
    final s = computeLifetimeStats(entries);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
          title: const Text('내 기록 요약',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: s.isEmpty
          ? const Center(
              child: Text('아직 기록이 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            icon: Icons.edit_note,
                            label: '총 기록',
                            value: '${s.totalEntries}개')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Stat(
                            icon: Icons.menu_book,
                            label: '일기장',
                            value: '$journals개')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            icon: Icons.text_fields,
                            label: '쓴 글자',
                            value: '${s.totalChars}자')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Stat(
                            icon: Icons.event_available,
                            label: '기록한 날',
                            value: '${s.recordedDays}일')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _Stat(
                            icon: Icons.local_fire_department,
                            label: '최장 연속',
                            value: '${s.longestStreak}일')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Stat(
                            icon: Icons.flag,
                            label: '첫 기록',
                            value: s.firstDate == null
                                ? '-'
                                : DateFormat('yyyy.M.d', locale)
                                    .format(s.firstDate!))),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
