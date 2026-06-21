import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/db/app_database.dart';
import 'package:lifelog/features/entries/diary_repository.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

/// Mirrors EntriesNotifier.clearMood: save(entry.copyWith(clearMood: true))
/// with no updatedAt bump, so removing a mood doesn't flag it as "수정됨".
void main() {
  group('copyWith clearMood', () {
    test('clears the mood, overriding any passed mood', () {
      final created = DateTime(2026, 6, 10, 9);
      final entry = DiaryEntry(
        entryId: 'c1',
        userId: 'me',
        journalId: 'jr_default',
        content: '기분 있는 기록',
        mood: Mood.good,
        createdAt: created,
        updatedAt: created,
      );
      expect(entry.copyWith(clearMood: true).mood, isNull);
      // clearMood wins over a positional mood arg
      expect(entry.copyWith(mood: Mood.hard, clearMood: true).mood, isNull);
      // without the flag the mood is preserved
      expect(entry.copyWith().mood, Mood.good);
    });
  });

  test('clearMood persists null without touching updatedAt', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = DiaryRepository(db);
    addTearDown(db.close);

    final created = DateTime(2026, 6, 10, 9);
    final entry = DiaryEntry(
      entryId: 'c2',
      userId: 'me',
      journalId: 'jr_default',
      content: '좋았던 기록',
      mood: Mood.good,
      createdAt: created,
      updatedAt: created,
    );
    await repo.insert(entry);
    expect((await repo.getAll()).single.mood, Mood.good);

    await repo.save(entry.copyWith(clearMood: true));

    final loaded = (await repo.getAll()).single;
    expect(loaded.mood, isNull);
    expect(loaded.updatedAt, created);
  });
}
