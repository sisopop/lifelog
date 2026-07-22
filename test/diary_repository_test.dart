import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/db/app_database.dart';
import 'package:lifelog/features/entries/diary_repository.dart';
import 'package:lifelog/shared/models/diary_entry.dart';
import 'package:lifelog/shared/models/enums.dart';

void main() {
  late AppDatabase db;
  late DiaryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DiaryRepository(db);
  });

  tearDown(() => db.close());

  test('seedIfEmpty inserts demo data once', () async {
    await repo.seedIfEmpty();
    expect((await repo.getAll()).length, 2);
    // running again must not duplicate
    await repo.seedIfEmpty();
    expect((await repo.getAll()).length, 2);
  });

  test('insert adds an entry and round-trips list/enum fields', () async {
    final entry = DiaryEntry(
      entryId: 'x1',
      userId: 'me',
      journalId: 'jr_default',
      title: '테스트',
      content: '본문',
      mood: Mood.good,
      visibility: EntryVisibility.private,
      tags: const ['a', 'b'],
      mediaUrls: const ['/tmp/p.jpg'],
      createdAt: DateTime(2026, 6, 14),
      updatedAt: DateTime(2026, 6, 14),
    );
    await repo.insert(entry);

    final loaded = (await repo.getAll()).firstWhere((e) => e.entryId == 'x1');
    expect(loaded.mood, Mood.good);
    expect(loaded.visibility, EntryVisibility.private);
    expect(loaded.tags, ['a', 'b']);
    expect(loaded.mediaUrls, ['/tmp/p.jpg']);
  });

  test('save upserts and updates visibility', () async {
    final entry = DiaryEntry(
      entryId: 'x2',
      userId: 'me',
      journalId: 'jr_default',
      content: '본문',
      createdAt: DateTime(2026, 6, 14),
      updatedAt: DateTime(2026, 6, 14),
    );
    await repo.insert(entry);
    await repo.save(entry.copyWith(visibility: EntryVisibility.public));

    final loaded = (await repo.getAll()).firstWhere((e) => e.entryId == 'x2');
    expect(loaded.visibility, EntryVisibility.public);
    // upsert, not duplicate
    expect((await repo.getAll()).where((e) => e.entryId == 'x2').length, 1);
  });

  test('contentRich round-trips through the db', () async {
    const rich = '[{"insert":"굵게","attributes":{"bold":true}},{"insert":"\\n"}]';
    await repo.insert(DiaryEntry(
      entryId: 'rich1',
      userId: 'me',
      journalId: 'jr_default',
      content: '굵게',
      contentRich: rich,
      createdAt: DateTime(2026, 6, 14),
      updatedAt: DateTime(2026, 6, 14),
    ));
    final loaded = (await repo.getAll()).firstWhere((e) => e.entryId == 'rich1');
    expect(loaded.contentRich, rich);
    expect(loaded.content, '굵게');
  });

  test('contentRich null (plain entry) round-trips as null', () async {
    await repo.insert(DiaryEntry(
      entryId: 'plain1',
      userId: 'me',
      journalId: 'jr_default',
      content: '서식없는 본문',
      createdAt: DateTime(2026, 6, 14),
      updatedAt: DateTime(2026, 6, 14),
    ));
    final loaded =
        (await repo.getAll()).firstWhere((e) => e.entryId == 'plain1');
    expect(loaded.contentRich, isNull);
  });

  test('copyWith clearContentRich drops rich formatting', () {
    final e = DiaryEntry(
      entryId: 'c1',
      userId: 'me',
      journalId: 'jr_default',
      content: '본문',
      contentRich: '[{"insert":"본문\\n"}]',
      createdAt: DateTime(2026, 6, 14),
      updatedAt: DateTime(2026, 6, 14),
    );
    expect(e.copyWith().contentRich, isNotNull); // 기본은 유지
    expect(e.copyWith(clearContentRich: true).contentRich, isNull);
  });

  test('getAll orders newest first', () async {
    await repo.insert(DiaryEntry(
      entryId: 'old',
      userId: 'me',
      journalId: 'jr_default',
      content: 'old',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
    await repo.insert(DiaryEntry(
      entryId: 'new',
      userId: 'me',
      journalId: 'jr_default',
      content: 'new',
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    ));
    final all = await repo.getAll();
    expect(all.first.entryId, 'new');
  });
}
