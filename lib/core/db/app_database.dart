import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../shared/models/enums.dart';

part 'app_database.g.dart';

/// Stores a `List<String>` (tags / media urls) as a JSON text column.
/// The local cache is denormalized on purpose — the normalized tag/media
/// tables live on the backend (see TECH_DESIGN.md).
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Local cache table for diary entries.
/// Generated row class is named `DiaryEntryRow` to avoid clashing with the
/// domain model `DiaryEntry`.
/// Local cache table for journals (일기장) — the grouping/sharing unit.
@DataClassName('JournalRow')
class Journals extends Table {
  TextColumn get journalId => text()();
  TextColumn get ownerId => text()();
  TextColumn get type => textEnum<JournalType>()();
  TextColumn get title => text()();
  IntColumn get coverColor => integer().withDefault(const Constant(0xFF7C6FF0))();
  TextColumn get coverPattern => text().withDefault(const Constant('none'))();
  TextColumn get coverBinding =>
      text().withDefault(const Constant('plain'))();
  TextColumn get coverCorner =>
      text().withDefault(const Constant('none'))();
  TextColumn get coverBand =>
      text().withDefault(const Constant('none'))();
  TextColumn get coverRibbon =>
      text().withDefault(const Constant('none'))();
  TextColumn get coverClip =>
      text().withDefault(const Constant('none'))();
  TextColumn get coverTab =>
      text().withDefault(const Constant('none'))();
  TextColumn get coverTexture =>
      text().withDefault(const Constant('none'))();
  TextColumn get icon => text().nullable()();
  TextColumn get status => textEnum<JournalStatus>()();
  TextColumn get spaceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {journalId};
}

/// Participants of a shared journal (couple/exchange). Personal journals
/// keep a single owner row.
@DataClassName('JournalMemberRow')
class JournalMembers extends Table {
  TextColumn get memberId => text()();
  TextColumn get journalId => text()();
  TextColumn get userId => text()();
  TextColumn get displayName => text()();
  TextColumn get role => textEnum<MemberRole>()();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
  DateTimeColumn get joinedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {memberId};
}

@DataClassName('DiaryEntryRow')
class DiaryEntries extends Table {
  TextColumn get entryId => text()();
  TextColumn get userId => text()();
  // Owning journal. Default lets the v1→v2 migration backfill existing rows.
  TextColumn get journalId =>
      text().withDefault(const Constant('jr_default'))();
  TextColumn get replyToEntryId => text().nullable()();
  TextColumn get lang => text().withDefault(const Constant('ko'))();
  TextColumn get title => text().nullable()();
  TextColumn get content => text()();
  TextColumn get aiSummary => text().nullable()();
  TextColumn get aiStatus => textEnum<AiStatus>()();
  TextColumn get mood => textEnum<Mood>().nullable()();
  TextColumn get visibility => textEnum<EntryVisibility>()();
  TextColumn get location => text().nullable()();
  TextColumn get tags => text().map(const StringListConverter())();
  TextColumn get mediaUrls => text().map(const StringListConverter())();
  // 즐겨찾기. Default lets the v3→v4 migration backfill existing rows.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {entryId};
}

@DriftDatabase(tables: [DiaryEntries, Journals, JournalMembers])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              name: 'lifelog',
              // Web needs explicit wasm + worker locations (files live in web/).
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ));

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Journal-centric restructure: add journals table + entry columns.
            // Existing entries get journalId='jr_default'/lang='ko' via the
            // column defaults; JournalRepository seeds the matching journal.
            await m.createTable(journals);
            await m.addColumn(diaryEntries, diaryEntries.journalId);
            await m.addColumn(diaryEntries, diaryEntries.replyToEntryId);
            await m.addColumn(diaryEntries, diaryEntries.lang);
          }
          if (from < 3) {
            // Shared-journal participants (커플/교환 멤버).
            await m.createTable(journalMembers);
          }
          if (from < 4) {
            // 즐겨찾기 flag — existing rows default to false via the column default.
            await m.addColumn(diaryEntries, diaryEntries.isFavorite);
          }
          if (from < 5) {
            // 다꾸 표지 패턴 — existing journals default to 'none' (단색).
            await m.addColumn(journals, journals.coverPattern);
          }
          if (from < 6) {
            // 다꾸 제본 방식 — existing journals default to 'plain' (무선).
            await m.addColumn(journals, journals.coverBinding);
          }
          if (from < 7) {
            // 다꾸 모서리 장식 — existing journals default to 'none' (없음).
            await m.addColumn(journals, journals.coverCorner);
          }
          if (from < 8) {
            // 다꾸 밴드(스트랩) — existing journals default to 'none' (없음).
            await m.addColumn(journals, journals.coverBand);
          }
          if (from < 9) {
            // 다꾸 책갈피 리본 — existing journals default to 'none' (없음).
            await m.addColumn(journals, journals.coverRibbon);
          }
          if (from < 10) {
            // 다꾸 클립(페이퍼클립) — existing journals default to 'none' (없음).
            await m.addColumn(journals, journals.coverClip);
          }
          if (from < 11) {
            // 다꾸 우측 인덱스 탭 — existing journals default to 'none' (없음).
            await m.addColumn(journals, journals.coverTab);
          }
          if (from < 12) {
            // 다꾸 표지 재질(가죽/크라프트/패브릭) — default 'none' (매끈한 단색).
            await m.addColumn(journals, journals.coverTexture);
          }
        },
      );

  Future<List<DiaryEntryRow>> getAllEntries() {
    return (select(diaryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<DiaryEntryRow>> getEntriesByJournal(String journalId) {
    return (select(diaryEntries)
          ..where((t) => t.journalId.equals(journalId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<void> upsertEntry(DiaryEntriesCompanion entry) {
    return into(diaryEntries).insertOnConflictUpdate(entry);
  }

  Future<void> deleteEntry(String entryId) {
    return (delete(diaryEntries)..where((t) => t.entryId.equals(entryId))).go();
  }

  Future<int> countEntries() async {
    final c = countAll();
    final q = selectOnly(diaryEntries)..addColumns([c]);
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  // ---- journals ----

  Future<List<JournalRow>> getAllJournals() {
    return (select(journals)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> upsertJournal(JournalsCompanion journal) {
    return into(journals).insertOnConflictUpdate(journal);
  }

  Future<void> deleteJournal(String journalId) {
    return (delete(journals)..where((t) => t.journalId.equals(journalId))).go();
  }

  Future<int> countJournals() async {
    final c = countAll();
    final q = selectOnly(journals)..addColumns([c]);
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  /// Number of entries per journal, for list badges.
  Future<Map<String, int>> entryCountsByJournal() async {
    final c = countAll();
    final q = selectOnly(diaryEntries)
      ..addColumns([diaryEntries.journalId, c])
      ..groupBy([diaryEntries.journalId]);
    final rows = await q.get();
    return {
      for (final r in rows)
        r.read(diaryEntries.journalId)!: r.read(c) ?? 0,
    };
  }

  // ---- members ----

  Future<List<JournalMemberRow>> getMembers(String journalId) {
    return (select(journalMembers)
          ..where((t) => t.journalId.equals(journalId))
          ..orderBy([(t) => OrderingTerm.asc(t.joinedAt)]))
        .get();
  }

  Future<List<JournalMemberRow>> getAllMembers() {
    return select(journalMembers).get();
  }

  Future<void> upsertMember(JournalMembersCompanion member) {
    return into(journalMembers).insertOnConflictUpdate(member);
  }

  Future<void> deleteMember(String memberId) {
    return (delete(journalMembers)..where((t) => t.memberId.equals(memberId)))
        .go();
  }
}
