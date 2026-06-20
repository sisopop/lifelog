import '../../shared/models/diary_entry.dart';
import '../../shared/models/journal.dart';

String _d2(int n) => n.toString().padLeft(2, '0');
String _ymd(DateTime d) => '${d.year}-${_d2(d.month)}-${_d2(d.day)}';

/// Serializes all journals + entries into a human-readable Markdown backup.
/// Entries are grouped by journal (in [journals] order) and sorted newest
/// first; replies are marked with "↳". Journals with no entries are skipped.
/// Entries whose journal is missing are collected under a "기타" section.
String exportMarkdown(
  List<Journal> journals,
  List<DiaryEntry> entries,
  DateTime now,
) {
  final byJournal = <String, List<DiaryEntry>>{};
  for (final e in entries) {
    byJournal.putIfAbsent(e.journalId, () => []).add(e);
  }

  final buf = StringBuffer()
    ..writeln('# lifelog 내보내기 (${_ymd(now)})')
    ..writeln()
    ..writeln('총 ${entries.length}개 기록 · 일기장 ${journals.length}개')
    ..writeln();

  void writeSection(String heading, List<DiaryEntry> list) {
    if (list.isEmpty) return;
    final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    buf
      ..writeln('## $heading')
      ..writeln();
    for (final e in sorted) {
      final reply = e.replyToEntryId != null ? '↳ ' : '';
      final mood = e.mood != null ? ' ${e.mood!.emoji}' : '';
      buf.writeln('### $reply${_ymd(e.createdAt)} · ${e.title ?? '제목 없음'}$mood');
      buf.writeln(e.content);
      if (e.tags.isNotEmpty) {
        buf.writeln('태그: ${e.tags.map((t) => '#$t').join(' ')}');
      }
      buf.writeln();
    }
  }

  final known = <String>{};
  for (final j in journals) {
    known.add(j.journalId);
    writeSection(
      '${j.displayIcon} ${j.title} (${j.type.label})',
      byJournal[j.journalId] ?? const [],
    );
  }

  final orphans = [
    for (final e in entries)
      if (!known.contains(e.journalId)) e,
  ];
  writeSection('기타', orphans);

  return buf.toString().trimRight();
}
