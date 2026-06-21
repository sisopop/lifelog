import 'lifetime_stats.dart';

/// Builds a plain-text, shareable summary of lifetime stats from [stats].
/// An empty record set yields a short placeholder.
String lifetimeStatsShareText(LifetimeStats stats) {
  const header = '📊 내 기록 요약';
  if (stats.isEmpty) {
    return '$header\n\n아직 기록이 없어요.\n\n— lifelog';
  }

  final lines = <String>[
    header,
    '',
    '📝 총 기록 ${stats.totalEntries}개',
    '✍️ 쓴 글자 ${stats.totalChars}자',
    '📅 기록한 날 ${stats.recordedDays}일',
    '🔥 최장 연속 ${stats.longestStreak}일',
    '✏️ 평균 ${stats.avgCharsPerEntry}자/기록',
  ];

  final first = stats.firstDate;
  if (first != null) {
    lines.add('🌱 첫 기록 ${first.year}.${first.month}.${first.day}');
  }

  lines
    ..add('')
    ..add('— lifelog');
  return lines.join('\n');
}
