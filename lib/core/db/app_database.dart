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
@DataClassName('DiaryEntryRow')
class DiaryEntries extends Table {
  TextColumn get entryId => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text()();
  TextColumn get aiSummary => text().nullable()();
  TextColumn get aiStatus => textEnum<AiStatus>()();
  TextColumn get mood => textEnum<Mood>().nullable()();
  TextColumn get visibility => textEnum<EntryVisibility>()();
  TextColumn get location => text().nullable()();
  TextColumn get tags => text().map(const StringListConverter())();
  TextColumn get mediaUrls => text().map(const StringListConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {entryId};
}

@DriftDatabase(tables: [DiaryEntries])
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
  int get schemaVersion => 1;

  Future<List<DiaryEntryRow>> getAllEntries() {
    return (select(diaryEntries)
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
}
