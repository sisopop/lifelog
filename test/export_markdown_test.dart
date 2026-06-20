import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/export/export_markdown.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';
import 'package:lifelog/shared/models/journal.dart';

Journal _j(String id, String title, {JournalType type = JournalType.personal}) =>
    Journal(
      journalId: id,
      ownerId: 'me',
      type: type,
      title: title,
      icon: '📓',
      createdAt: DateTime(2026, 1, 1),
    );

DiaryEntry _e({
  required String id,
  required String journalId,
  required DateTime at,
  String? title,
  String content = '본문',
  Mood? mood,
  List<String> tags = const [],
  String? replyTo,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'me',
      journalId: journalId,
      replyToEntryId: replyTo,
      title: title,
      content: content,
      mood: mood,
      tags: tags,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  final journals = [_j('j1', '나의 일기장'), _j('j2', '교환', type: JournalType.exchange)];

  test('groups by journal and includes header counts', () {
    final entries = [
      _e(id: '1', journalId: 'j1', at: DateTime(2026, 6, 12), title: '산책'),
      _e(id: '2', journalId: 'j2', at: DateTime(2026, 6, 11), title: '교환글'),
    ];
    final md = exportMarkdown(journals, entries, DateTime(2026, 6, 19));
    expect(md, contains('# lifelog 내보내기 (2026-06-19)'));
    expect(md, contains('총 2개 기록 · 일기장 2개'));
    expect(md, contains('## 📓 나의 일기장 (개인)'));
    expect(md, contains('### 2026-06-12 · 산책'));
    expect(md, contains('## 📓 교환 (교환)'));
  });

  test('newest first within a journal and marks replies + tags', () {
    final entries = [
      _e(id: '1', journalId: 'j1', at: DateTime(2026, 6, 10), title: '오래된'),
      _e(id: '2', journalId: 'j1', at: DateTime(2026, 6, 15), title: '최근', tags: ['여행']),
      _e(id: '3', journalId: 'j1', at: DateTime(2026, 6, 16), title: '답글', replyTo: '2'),
    ];
    final md = exportMarkdown(journals, entries, DateTime(2026, 6, 19));
    final iRecent = md.indexOf('최근');
    final iOld = md.indexOf('오래된');
    expect(iRecent < iOld, true); // newest appears first
    expect(md, contains('태그: #여행'));
    expect(md, contains('### ↳ 2026-06-16 · 답글'));
  });

  test('entries with unknown journal go under 기타', () {
    final entries = [
      _e(id: '9', journalId: 'ghost', at: DateTime(2026, 6, 1), title: '미아'),
    ];
    final md = exportMarkdown(journals, entries, DateTime(2026, 6, 19));
    expect(md, contains('## 기타'));
    expect(md, contains('미아'));
  });

  test('empty journals are skipped', () {
    final md = exportMarkdown(journals, const [], DateTime(2026, 6, 19));
    expect(md, isNot(contains('## 📓 나의 일기장')));
  });
}
