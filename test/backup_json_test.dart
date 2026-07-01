import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/export/backup_json.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';
import 'package:lifelog/shared/models/journal.dart';

Journal _journal({
  String id = 'jr_1',
  String title = '나의 일기장',
  JournalType type = JournalType.personal,
  String? icon,
  DateTime? createdAt,
  DateTime? deletedAt,
}) =>
    Journal(
      journalId: id,
      ownerId: 'u_1',
      type: type,
      title: title,
      icon: icon,
      iconX: 0.25,
      iconY: 0.75,
      createdAt: createdAt ?? DateTime(2026, 1, 1, 9),
      deletedAt: deletedAt,
    );

DiaryEntry _entry({
  String id = 'e_1',
  String journalId = 'jr_1',
  String content = '오늘의 기록',
  String? title,
  String? replyTo,
  Mood? mood,
  String? location,
  String? aiSummary,
  EntryVisibility visibility = EntryVisibility.private,
  List<String> tags = const [],
  List<String> mediaUrls = const [],
  bool isFavorite = false,
  DateTime? at,
  DateTime? deletedAt,
  String? pageCanvas,
  String? flowPhotos,
}) =>
    DiaryEntry(
      entryId: id,
      userId: 'u_1',
      journalId: journalId,
      replyToEntryId: replyTo,
      title: title,
      content: content,
      aiSummary: aiSummary,
      aiStatus: aiSummary != null ? AiStatus.done : AiStatus.none,
      mood: mood,
      visibility: visibility,
      location: location,
      createdAt: at ?? DateTime(2026, 6, 13, 14, 30),
      updatedAt: at ?? DateTime(2026, 6, 13, 14, 30),
      mediaUrls: mediaUrls,
      tags: tags,
      pageCanvas: pageCanvas,
      flowPhotos: flowPhotos,
      isFavorite: isFavorite,
      deletedAt: deletedAt,
    );

void main() {
  group('exportBackupJson', () {
    test('produces a versioned lifelog document', () {
      final json = exportBackupJson(
          [_journal()], [_entry()], DateTime(2026, 6, 29, 10));
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect(map['app'], 'lifelog');
      expect(map['version'], kBackupFormatVersion);
      expect(map['exportedAt'], isA<String>());
      expect((map['journals'] as List).length, 1);
      expect((map['entries'] as List).length, 1);
    });
  });

  group('round-trip', () {
    test('every field survives export → parse', () {
      final journals = [
        _journal(icon: '📔', deletedAt: DateTime(2026, 6, 1)),
        _journal(id: 'jr_2', title: '교환일기', type: JournalType.exchange),
      ];
      final entries = [
        _entry(
          title: '제목 있음',
          mood: Mood.good,
          location: '제주도',
          aiSummary: '요약문',
          visibility: EntryVisibility.link,
          tags: ['추억', '가족'],
          mediaUrls: ['file://a.jpg'],
          isFavorite: true,
        ),
        _entry(id: 'e_2', replyTo: 'e_1', content: '답장'),
        _entry(id: 'e_3', deletedAt: DateTime(2026, 6, 20)),
      ];

      final data =
          parseBackupJson(exportBackupJson(journals, entries, DateTime(2026, 6, 29)));

      expect(data.version, kBackupFormatVersion);
      expect(data.journals.length, 2);
      expect(data.entries.length, 3);

      final j = data.journals.first;
      expect(j.journalId, 'jr_1');
      expect(j.icon, '📔');
      expect(j.iconX, 0.25);
      expect(j.iconY, 0.75);
      expect(j.deletedAt, DateTime(2026, 6, 1));

      final e = data.entries.first;
      expect(e.title, '제목 있음');
      expect(e.mood, Mood.good);
      expect(e.location, '제주도');
      expect(e.aiSummary, '요약문');
      expect(e.visibility, EntryVisibility.link);
      expect(e.tags, ['추억', '가족']);
      expect(e.mediaUrls, ['file://a.jpg']);
      expect(e.isFavorite, isTrue);
      expect(e.createdAt, DateTime(2026, 6, 13, 14, 30));

      expect(data.entries[1].replyToEntryId, 'e_1');
      expect(data.entries[2].deletedAt, DateTime(2026, 6, 20));
    });

    test('pageCanvas JSON survives export → parse', () {
      const canvas = '{"version":1,"paper":"grid","layers":[]}';
      final data = parseBackupJson(exportBackupJson(
          [_journal()], [_entry(pageCanvas: canvas)], DateTime(2026, 6, 29)));
      expect(data.entries.first.pageCanvas, canvas);
    });

    test('flowPhotos JSON survives export → parse (null stays null)', () {
      const flow = '[{"path":"data:image/png;base64,AA","afterParagraph":1}]';
      final data = parseBackupJson(exportBackupJson(
          [_journal()], [_entry(flowPhotos: flow)], DateTime(2026, 6, 29)));
      expect(data.entries.first.flowPhotos, flow);
      final none = parseBackupJson(
          exportBackupJson([_journal()], [_entry()], DateTime(2026, 6, 29)));
      expect(none.entries.first.flowPhotos, isNull);
    });

    test('null optional fields stay null', () {
      final data = parseBackupJson(
          exportBackupJson([_journal()], [_entry()], DateTime(2026, 6, 29)));
      final e = data.entries.first;
      expect(e.title, isNull);
      expect(e.mood, isNull);
      expect(e.location, isNull);
      expect(e.aiSummary, isNull);
      expect(e.replyToEntryId, isNull);
      expect(e.deletedAt, isNull);
      expect(e.pageCanvas, isNull);
      expect(e.tags, isEmpty);
    });

    test('empty backup round-trips', () {
      final data =
          parseBackupJson(exportBackupJson(const [], const [], DateTime(2026, 6, 29)));
      expect(data.journals, isEmpty);
      expect(data.entries, isEmpty);
    });
  });

  group('summarizeRestore', () {
    test('classifies records as new vs overwrite by id', () {
      final backup = BackupData(
        version: 1,
        journals: [_journal(id: 'jr_1'), _journal(id: 'jr_new')],
        entries: [
          _entry(id: 'e_1'),
          _entry(id: 'e_2'),
          _entry(id: 'e_new'),
        ],
      );
      final s = summarizeRestore(
        existingJournalIds: {'jr_1'},
        existingEntryIds: {'e_1', 'e_2'},
        backup: backup,
      );
      expect(s.newJournals, 1);
      expect(s.updatedJournals, 1);
      expect(s.totalJournals, 2);
      expect(s.newEntries, 1);
      expect(s.updatedEntries, 2);
      expect(s.totalEntries, 3);
    });

    test('a self-restore (same ids) is all overwrite, nothing new', () {
      final backup = BackupData(
        version: 1,
        journals: [_journal(id: 'jr_1')],
        entries: [_entry(id: 'e_1'), _entry(id: 'e_2')],
      );
      final s = summarizeRestore(
        existingJournalIds: {'jr_1'},
        existingEntryIds: {'e_1', 'e_2'},
        backup: backup,
      );
      expect(s.newJournals, 0);
      expect(s.newEntries, 0);
      expect(s.updatedJournals, 1);
      expect(s.updatedEntries, 2);
    });

    test('restoring into an empty app is all new', () {
      final backup = BackupData(
        version: 1,
        journals: [_journal(id: 'jr_1')],
        entries: [_entry(id: 'e_1')],
      );
      final s = summarizeRestore(
        existingJournalIds: const {},
        existingEntryIds: const {},
        backup: backup,
      );
      expect(s.newJournals, 1);
      expect(s.newEntries, 1);
      expect(s.updatedJournals, 0);
      expect(s.updatedEntries, 0);
    });
  });

  group('parseBackupJson guards', () {
    test('throws on non-JSON text', () {
      expect(() => parseBackupJson('not json{'),
          throwsA(isA<BackupParseException>()));
    });

    test('throws when it is not a lifelog backup', () {
      final foreign = jsonEncode({'app': 'other', 'journals': [], 'entries': []});
      expect(() => parseBackupJson(foreign),
          throwsA(isA<BackupParseException>()));
    });

    test('throws when an entry is missing a required field', () {
      final broken = jsonEncode({
        'app': 'lifelog',
        'version': 1,
        'journals': [],
        'entries': [
          {'entryId': 'e_1', 'content': 'x'} // no journalId / createdAt
        ],
      });
      expect(() => parseBackupJson(broken),
          throwsA(isA<BackupParseException>()));
    });

    test('unknown enum names fall back instead of throwing', () {
      final json = jsonEncode({
        'app': 'lifelog',
        'version': 1,
        'journals': [],
        'entries': [
          {
            'entryId': 'e_1',
            'journalId': 'jr_1',
            'content': 'x',
            'mood': 'ecstatic', // not a real Mood
            'visibility': 'whoknows', // not a real visibility
            'createdAt': '2026-06-13T14:30:00.000',
            'updatedAt': '2026-06-13T14:30:00.000',
          }
        ],
      });
      final data = parseBackupJson(json);
      expect(data.entries.first.mood, isNull);
      expect(data.entries.first.visibility, EntryVisibility.private);
    });
  });
}
