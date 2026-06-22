part of 'lifetime_stats_screen.dart';

/// A single soft highlight line for a one-off insight.
class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark),
      ),
    );
  }
}

/// Tappable highlight for the user's longest record; opens the entry.
class _LongestEntryCard extends StatelessWidget {
  const _LongestEntryCard({
    required this.entry,
    required this.chars,
    required this.locale,
  });

  final DiaryEntry entry;
  final int chars;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final title = (entry.title?.trim().isNotEmpty ?? false)
        ? entry.title!.trim()
        : entry.content.trim();
    final date = DateFormat('yyyy.M.d', locale).format(entry.createdAt);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/entry/${entry.entryId}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📜 가장 긴 기록 ($chars자)',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
            const SizedBox(height: 6),
            Text('$date · $title',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// A proportional bar + legend showing how the recorded moods split.
class _MoodDistribution extends StatelessWidget {
  const _MoodDistribution({required this.counts});
  final Map<Mood, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('감정 분포',
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                for (final e in counts.entries)
                  Expanded(
                    flex: e.value,
                    child: Container(height: 14, color: moodColor(e.key)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final e in counts.entries)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push(Uri(
                    path: '/mood',
                    queryParameters: {'m': e.key.name},
                  ).toString()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: moodColor(e.key), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${e.key.label} ${e.value}개 (${(e.value * 100 / total).round()}%)',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A soft, distinct color per day-part for the 시간대 분포 chart.
Color _dayPartColor(DayPart part) {
  switch (part) {
    case DayPart.dawn:
      return const Color(0xFF5C6BC0); // indigo — 새벽
    case DayPart.morning:
      return const Color(0xFFFFB74D); // orange — 아침
    case DayPart.afternoon:
      return const Color(0xFF4FC3F7); // sky — 오후
    case DayPart.evening:
      return const Color(0xFF9575CD); // violet — 저녁
  }
}

/// A proportional bar + legend showing how records split across the day.
class _DayPartDistribution extends StatelessWidget {
  const _DayPartDistribution({required this.counts});
  final Map<DayPart, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('시간대 분포',
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                for (final e in counts.entries)
                  Expanded(
                    flex: e.value,
                    child:
                        Container(height: 14, color: _dayPartColor(e.key)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final e in counts.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: _dayPartColor(e.key),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key.emoji} ${e.key.label} ${e.value}개 '
                      '(${(e.value * 100 / total).round()}%)',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small vertical-bar chart of the last few months' record counts.
class _MonthlyTrend extends StatelessWidget {
  const _MonthlyTrend({required this.months});
  final List<MonthCount> months;

  @override
  Widget build(BuildContext context) {
    final max = months.fold<int>(0, (a, m) => m.count > a ? m.count : a);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('최근 6개월 추이',
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 16),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final m in months)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(m.count > 0 ? '${m.count}' : '',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark)),
                        const SizedBox(height: 4),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: max == 0 ? 2 : 6 + (72 * m.count / max),
                          decoration: BoxDecoration(
                            color: m.count > 0
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${m.month}월',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Most-used tags as size-graded chips; tapping opens that tag's records.
class _TagCloud extends StatelessWidget {
  const _TagCloud({required this.tags});
  final List<MapEntry<String, int>> tags;

  @override
  Widget build(BuildContext context) {
    final max = tags.first.value; // tags is sorted desc, so first is largest
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('자주 쓴 태그',
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                _TagChip(tag: t.key, count: t.value, weight: t.value / max),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(
      {required this.tag, required this.count, required this.weight});
  final String tag;
  final int count;
  final double weight; // 0..1 relative to the most-used tag

  @override
  Widget build(BuildContext context) {
    final fontSize = 13.0 + weight * 5; // 13–18
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(
        Uri(path: '/tag', queryParameters: {'t': tag}).toString(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '#$tag $count',
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark),
        ),
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
