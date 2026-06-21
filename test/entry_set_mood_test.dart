import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/db/app_database.dart';
import 'package:lifelog/features/entries/diary_repository.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

/// Mirrors EntriesNotifier.setMood: save(entry.copyWith(mood: m)) with no
/// updatedAt bump, so attaching a mood doesn't flag the entry as "수정됨".
void main() {
  late AppDatabase db;
  late DiaryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DiaryRepository(db);
  });

  tearDown(() => db.close());

  test('attaching a mood persists it without touching updatedAt', () async {
    final created = DateTime(2026, 6, 10, 9);
    final entry = DiaryEntry(
      entryId: 'm1',
      userId: 'me',
      journalId: 'jr_default',
      content: '기분 없이 저장된 기록',
      createdAt: created,
      updatedAt: created,
    );
    await repo.insert(entry);
    expect((await repo.getAll()).single.mood, isNull);

    await repo.save(entry.copyWith(mood: Mood.good));

    final loaded = (await repo.getAll()).single;
    expect(loaded.mood, Mood.good);
    // updatedAt unchanged → wasEdited stays false
    expect(loaded.updatedAt, created);
    expect(loaded.updatedAt, loaded.createdAt);
  });
}
