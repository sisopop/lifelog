part of 'review_screen.dart';

/// Tappable highlight for the month's longest record; opens the entry.
class _MonthLongestCard extends StatelessWidget {
  const _MonthLongestCard({required this.entry, required this.chars});
  final DiaryEntry entry;
  final int chars;

  @override
  Widget build(BuildContext context) {
    final title = (entry.title?.trim().isNotEmpty ?? false)
        ? entry.title!.trim()
        : entry.content.trim();
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
            Text('📜 이번 달 가장 긴 기록 ($chars자)',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark)),
            const SizedBox(height: 6),
            Text(title,
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

/// Horizontal chip row scoping all 회고 stats to 전체 or one journal.
class _JournalFilterRow extends ConsumerWidget {
  const _JournalFilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journals = (ref.watch(journalsProvider).asData?.value ?? const [])
        .where((j) => !j.isArchived)
        .toList();
    if (journals.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(reviewJournalProvider);
    final ctrl = ref.read(reviewJournalProvider.notifier);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: '전체',
            selected: selected == null,
            onTap: () => ctrl.select(null),
          ),
          for (final j in journals)
            _FilterChip(
              label: '${j.displayIcon} ${j.title}',
              selected: selected == j.journalId,
              onTap: () => ctrl.select(j.journalId),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.primarySoft,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
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
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// One-line month-over-month change in record count. Color and icon shift
/// with the sign; a flat month reads as "지난달과 같아요".
class _DeltaLine extends StatelessWidget {
  const _DeltaLine(this.delta);
  final int delta;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String text;
    if (delta > 0) {
      icon = Icons.trending_up;
      color = AppColors.primaryDark;
      text = '지난달보다 $delta개 더 기록했어요';
    } else if (delta < 0) {
      icon = Icons.trending_down;
      color = AppColors.textSecondary;
      text = '지난달보다 ${-delta}개 적게 기록했어요';
    } else {
      icon = Icons.trending_flat;
      color = AppColors.textSecondary;
      text = '지난달과 같은 개수예요';
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

/// History-wide streak banner (current run + best run).
class _StreakBanner extends StatelessWidget {
  const _StreakBanner(this.streak);
  final StreakInfo streak;

  @override
  Widget build(BuildContext context) {
    final cur = streak.current;
    final headline =
        cur > 0 ? '🔥 $cur일 연속 기록 중!' : '오늘 기록하고 연속 기록을 시작해보세요';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('최장 연속 기록 ${streak.longest}일',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Small legend explaining the calendar's mood colors.
class _MoodLegend extends StatelessWidget {
  const _MoodLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final m in Mood.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: moodColor(m), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(m.label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
      ],
    );
  }
}

/// Vertical bar chart of top-level record counts per weekday (일~토).
class _WeekdayChart extends StatelessWidget {
  const _WeekdayChart(this.counts);
  final List<int> counts;

  static const _labels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final max = counts.fold<int>(0, (m, c) => c > m ? c : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(counts[i] > 0 ? '${counts[i]}' : '',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Container(
                    height: 80 * (max == 0 ? 0 : counts[i] / max),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: counts[i] > 0
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(minHeight: 4),
                  ),
                  const SizedBox(height: 6),
                  Text(_labels[i],
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  const _MoodBar(this.mood, this.ratio);
  final Mood mood;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('${mood.emoji} ${mood.label}', style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(moodColor(mood)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${(ratio * 100).round()}%', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
