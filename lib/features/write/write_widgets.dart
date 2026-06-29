part of 'write_screen.dart';

/// Header chip showing the target journal. Tappable (with a ▾) when the
/// journal can be changed; otherwise a static label.
class _JournalSelector extends StatelessWidget {
  const _JournalSelector({
    required this.journal,
    required this.canSwitch,
    this.onTap,
  });
  final Journal journal;
  final bool canSwitch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(journal.coverColor);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(journal.displayIcon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('일기장 · ',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Flexible(
              child: Text(
                journal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            if (canSwitch) ...[
              const Spacer(),
              const Text('변경',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Right-aligned meta below the content field: live char/word count, an
/// optional encouragement milestone, and a rough reading-time estimate once
/// the entry is long enough. All values come from pure helpers in
/// `text_stats.dart`.
class _ContentMeta extends StatelessWidget {
  const _ContentMeta(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = textStats(text);
    final milestone = writingMilestone(s.chars);
    final minutes = readingMinutes(s.chars);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '글자 ${s.chars} · 단어 ${s.words}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        if (minutes != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '📖 약 $minutes분 읽을 분량',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
        if (milestone != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              milestone,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.textSecondary),
      label: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
