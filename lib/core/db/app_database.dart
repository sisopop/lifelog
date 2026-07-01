import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

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
  TextColumn get coverFont =>
      text().withDefault(const Constant('pretendard'))();
  TextColumn get innerPaper =>
      text().withDefault(const Constant('plain'))();
  TextColumn get innerPaperColor =>
      text().withDefault(const Constant('cream'))();
  TextColumn get icon => text().nullable()();
  // 표지 아이콘의 자유 위치(스티커처럼 끌어 배치). 0~1 비율: x=0 왼쪽/1 오른쪽,
  // y=0 위/1 아래. 기존 일기장은 0/0(좌상단)으로 백필 — 종전 모습 유지.
  RealColumn get iconX => real().withDefault(const Constant(0.0))();
  RealColumn get iconY => real().withDefault(const Constant(0.0))();
  TextColumn get status => textEnum<JournalStatus>()();
  TextColumn get spaceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  // 휴지통: non-null = soft-deleted (kept 30 days, hidden from the home list).
  DateTimeColumn get deletedAt => dateTime().nullable()();

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
  // 페이지(내지) 꾸미기 캔버스 — 스티커/속지 등 자유 배치 문서의 JSON 직렬화.
  // null = 종전처럼 순수 텍스트 기록(꾸미기 없음). 본문 content는 그대로 유지.
  TextColumn get pageCanvas => text().nullable()();
  // 즐겨찾기. Default lets the v3→v4 migration backfill existing rows.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  // 휴지통: non-null = soft-deleted (kept 30 days, hidden from normal lists).
  DateTimeColumn get deletedAt => dateTime().nullable()();
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
  int get schemaVersion => 19;

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
          if (from < 13) {
            // 다꾸 제목 글꼴 — existing journals default to 'pretendard' (앱 기본).
            await m.addColumn(journals, journals.coverFont);
          }
          if (from < 14) {
            // 다꾸 속지(내지) — existing journals default to 'plain' (무지).
            await m.addColumn(journals, journals.innerPaper);
          }
          if (from < 15) {
            // 속지 종이 바탕색 — existing journals default to 'cream' (크림).
            await m.addColumn(journals, journals.innerPaperColor);
          }
          if (from < 16) {
            // 휴지통: soft-delete column on entries (null = live).
            await m.addColumn(diaryEntries, diaryEntries.deletedAt);
          }
          if (from < 17) {
            // 휴지통: soft-delete column on journals (null = live).
            await m.addColumn(journals, journals.deletedAt);
          }
          if (from < 18) {
            // 표지 아이콘 자유 위치 — existing journals default to 0/0 (좌상단).
            await m.addColumn(journals, journals.iconX);
            await m.addColumn(journals, journals.iconY);
          }
          if (from < 19) {
            // 페이지(내지) 꾸미기 캔버스 JSON — existing entries default to null
            // (꾸미기 없는 순수 텍스트 기록 그대로).
            await m.addColumn(diaryEntries, diaryEntries.pageCanvas);
          }
        },
        // Self-heal: on the web (drift WASM) an addColumn that failed mid-upgrade
        // can leave the stored schema version bumped while the column is still
        // missing — so onUpgrade never re-runs and every journals SELECT throws
        // (journals vanish while entries, a different table, survive). Running an
        // idempotent column check on EVERY open recovers such a stuck DB without
        // touching any data. Adds only columns that aren't already present.
        beforeOpen: (details) async {
          await ensureJournalColumns();
          await ensureEntryColumns();
        },
      );

  /// Adds any 다꾸/속지 columns missing from the `journals` table. Safe to run
  /// repeatedly: it inspects PRAGMA table_info first and only adds gaps.
  /// Public so the self-heal can be unit-tested against a simulated stuck DB.
  @visibleForTesting
  Future<void> ensureJournalColumns() async {
    final info = await customSelect(
      'PRAGMA table_info(journals)',
    ).get();
    final present = info.map((r) => r.read<String>('name')).toSet();
    final m = createMigrator();
    final expected = <String, GeneratedColumn<Object>>{
      'cover_pattern': journals.coverPattern,
      'cover_binding': journals.coverBinding,
      'cover_corner': journals.coverCorner,
      'cover_band': journals.coverBand,
      'cover_ribbon': journals.coverRibbon,
      'cover_clip': journals.coverClip,
      'cover_tab': journals.coverTab,
      'cover_texture': journals.coverTexture,
      'cover_font': journals.coverFont,
      'inner_paper': journals.innerPaper,
      'inner_paper_color': journals.innerPaperColor,
      'deleted_at': journals.deletedAt,
      'icon_x': journals.iconX,
      'icon_y': journals.iconY,
    };
    for (final entry in expected.entries) {
      if (!present.contains(entry.key)) {
        // Defensive: a concurrent open (web worker) may add it first — a
        // "duplicate column" error here must not abort the whole open.
        try {
          await m.addColumn(journals, entry.value);
        } catch (_) {}
      }
    }
  }

  /// Adds any 휴지통/sync columns missing from the `diary_entries` table. Same
  /// idempotent self-heal as [ensureJournalColumns] — recovers a web (drift
  /// WASM) DB whose stored schema version got bumped while a column add failed
  /// mid-upgrade, so entries would otherwise vanish on every SELECT.
  @visibleForTesting
  Future<void> ensureEntryColumns() async {
    final info = await customSelect(
      'PRAGMA table_info(diary_entries)',
    ).get();
    final present = info.map((r) => r.read<String>('name')).toSet();
    final m = createMigrator();
    final expected = <String, GeneratedColumn<Object>>{
      'deleted_at': diaryEntries.deletedAt,
      'page_canvas': diaryEntries.pageCanvas,
    };
    for (final entry in expected.entries) {
      if (!present.contains(entry.key)) {
        try {
          await m.addColumn(diaryEntries, entry.value);
        } catch (_) {}
      }
    }
  }

  Future<List<DiaryEntryRow>> getAllEntries() {
    return (select(diaryEntries)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<DiaryEntryRow>> getEntriesByJournal(String journalId) {
    return (select(diaryEntries)
          ..where((t) => t.journalId.equals(journalId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Soft-deleted entries (휴지통), newest deletion first.
  Future<List<DiaryEntryRow>> getTrashedEntries() {
    return (select(diaryEntries)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .get();
  }

  Future<void> upsertEntry(DiaryEntriesCompanion entry) {
    return into(diaryEntries).insertOnConflictUpdate(entry);
  }

  /// 휴지통으로 보내기: marks the entry soft-deleted instead of removing it.
  Future<void> softDeleteEntry(String entryId, DateTime when) {
    return (update(diaryEntries)..where((t) => t.entryId.equals(entryId)))
        .write(DiaryEntriesCompanion(deletedAt: Value(when)));
  }

  /// 복원: clears the soft-delete flag.
  Future<void> restoreEntry(String entryId) {
    return (update(diaryEntries)..where((t) => t.entryId.equals(entryId)))
        .write(const DiaryEntriesCompanion(deletedAt: Value(null)));
  }

  /// Permanently removes an entry (used by trash purge / "영구 삭제").
  Future<void> deleteEntry(String entryId) {
    return (delete(diaryEntries)..where((t) => t.entryId.equals(entryId))).go();
  }

  /// Purges entries soft-deleted before [cutoff] (30-day auto-clean).
  Future<int> purgeEntriesDeletedBefore(DateTime cutoff) {
    return (delete(diaryEntries)
          ..where((t) =>
              t.deletedAt.isNotNull() & t.deletedAt.isSmallerThanValue(cutoff)))
        .go();
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
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Soft-deleted journals (휴지통), newest deletion first.
  Future<List<JournalRow>> getTrashedJournals() {
    return (select(journals)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .get();
  }

  Future<void> upsertJournal(JournalsCompanion journal) {
    return into(journals).insertOnConflictUpdate(journal);
  }

  /// 휴지통으로 보내기 (cascade soft delete). Stamps [when] on the journal AND
  /// every currently-live entry it owns, atomically — so the journal and its
  /// records vanish together (no orphan records left behind) and a later
  /// restore can revive exactly the entries this cascade trashed.
  Future<void> softDeleteJournalCascade(String journalId, DateTime when) {
    return transaction(() async {
      await (update(journals)..where((t) => t.journalId.equals(journalId)))
          .write(JournalsCompanion(deletedAt: Value(when)));
      await (update(diaryEntries)
            ..where((t) =>
                t.journalId.equals(journalId) & t.deletedAt.isNull()))
          .write(DiaryEntriesCompanion(deletedAt: Value(when)));
    });
  }

  /// 복원: clears the journal's deletedAt and revives only the entries trashed
  /// by the same cascade (deletedAt == [when]), so records the user had
  /// individually trashed earlier stay in the bin.
  Future<void> restoreJournalCascade(String journalId, DateTime when) {
    return transaction(() async {
      await (update(journals)..where((t) => t.journalId.equals(journalId)))
          .write(const JournalsCompanion(deletedAt: Value(null)));
      await (update(diaryEntries)
            ..where((t) =>
                t.journalId.equals(journalId) &
                t.deletedAt.equals(when)))
          .write(const DiaryEntriesCompanion(deletedAt: Value(null)));
    });
  }

  /// 영구 삭제: hard-removes a journal and all of its entries + members.
  Future<void> deleteJournalForever(String journalId) {
    return transaction(() async {
      await (delete(diaryEntries)..where((t) => t.journalId.equals(journalId)))
          .go();
      await (delete(journalMembers)
            ..where((t) => t.journalId.equals(journalId)))
          .go();
      await (delete(journals)..where((t) => t.journalId.equals(journalId)))
          .go();
    });
  }

  /// Purges journals soft-deleted before [cutoff] together with their entries
  /// and members (30-day auto-clean). Returns the number of journals purged.
  Future<int> purgeJournalsDeletedBefore(DateTime cutoff) async {
    final expired = await (select(journals)
          ..where((t) =>
              t.deletedAt.isNotNull() &
              t.deletedAt.isSmallerThanValue(cutoff)))
        .get();
    for (final j in expired) {
      await deleteJournalForever(j.journalId);
    }
    return expired.length;
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
      ..where(diaryEntries.deletedAt.isNull())
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
