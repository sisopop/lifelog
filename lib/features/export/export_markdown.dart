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

/// Serializes just the records of [year]/[month] into Markdown, grouped by
/// journal (in [journals] order) and sorted newest first; replies are marked
/// with "↳". Journals with no record that month are skipped. Returns a
/// header-only doc when the month has no records.
String exportMonthMarkdown(
  List<Journal> journals,
  List<DiaryEntry> entries,
  int year,
  int month,
  DateTime now,
) {
  final inMonth = [
    for (final e in entries)
      if (e.createdAt.year == year && e.createdAt.month == month) e,
  ];
  final byJournal = <String, List<DiaryEntry>>{};
  for (final e in inMonth) {
    byJournal.putIfAbsent(e.journalId, () => []).add(e);
  }

  final buf = StringBuffer()
    ..writeln('# lifelog $year년 $month월')
    ..writeln()
    ..writeln('기록 ${inMonth.length}개 · 내보낸 날짜 ${_ymd(now)}')
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
    for (final e in inMonth)
      if (!known.contains(e.journalId)) e,
  ];
  writeSection('기타', orphans);

  return buf.toString().trimRight();
}

/// Serializes a single [journal] and its [entries] (entries from other
/// journals are ignored) into Markdown. Records are newest first; replies are
/// marked with "↳". Returns a header-only doc when the journal has no records.
String exportJournalMarkdown(
  Journal journal,
  List<DiaryEntry> entries,
  DateTime now,
) {
  final mine = [
    for (final e in entries)
      if (e.journalId == journal.journalId) e,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final buf = StringBuffer()
    ..writeln('# ${journal.displayIcon} ${journal.title}')
    ..writeln()
    ..writeln('${journal.type.label} · 기록 ${mine.length}개 · 내보낸 날짜 ${_ymd(now)}')
    ..writeln();

  for (final e in mine) {
    final reply = e.replyToEntryId != null ? '↳ ' : '';
    final mood = e.mood != null ? ' ${e.mood!.emoji}' : '';
    buf.writeln('## $reply${_ymd(e.createdAt)} · ${e.title ?? '제목 없음'}$mood');
    buf.writeln(e.content);
    if (e.tags.isNotEmpty) {
      buf.writeln('태그: ${e.tags.map((t) => '#$t').join(' ')}');
    }
    buf.writeln();
  }

  return buf.toString().trimRight();
}
