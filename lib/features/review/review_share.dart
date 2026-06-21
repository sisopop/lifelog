import '../../shared/models/enums.dart';
import '../stats/stats_provider.dart';

/// Builds a plain-text, shareable summary of a month's review from [stats].
/// Mood lines show only moods that occurred; tags show up to the top 5 the
/// stats already carry. An empty month yields a short placeholder.
String monthlyReviewShareText(MonthlyStats stats) {
  final header = '📔 ${stats.year}년 ${stats.month}월 회고';
  if (stats.isEmpty) {
    return '$header\n\n이번 달엔 아직 기록이 없어요.\n\n— lifelog';
  }

  final lines = <String>[
    header,
    '',
    '✅ 기록한 날 ${stats.daysRecorded}일',
    '📝 총 기록 ${stats.total}개',
    '✍️ 쓴 글자 ${stats.charsWritten}자',
  ];

  final moodParts = <String>[];
  for (final m in Mood.values) {
    final ratio = stats.moodRatio[m] ?? 0;
    if (ratio > 0) {
      moodParts.add('${m.emoji} ${m.label} ${(ratio * 100).round()}%');
    }
  }
  if (moodParts.isNotEmpty) {
    lines
      ..add('')
      ..add(moodParts.join(' · '));
  }

  if (stats.topTags.isNotEmpty) {
    lines
      ..add('')
      ..add(stats.topTags.map((t) => '#${t.key} ${t.value}').join(' · '));
  }

  lines
    ..add('')
    ..add('— lifelog');
  return lines.join('\n');
}
