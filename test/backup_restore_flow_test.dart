import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lifelog/core/db/app_database.dart';
import 'package:lifelog/features/entries/diary_repository.dart';
import 'package:lifelog/features/export/backup_json.dart';
import 'package:lifelog/shared/models/diary_entry.dart';

/// 기기가 연결되지 않은 상황에서 설정 화면의 "전체 백업(JSON)" → "백업 복원"
/// 흐름(J2 수정)을 리포지토리 레벨에서 그대로 재현한다: 라이브 기록 1개 +
/// 휴지통 기록 1개(리치서식 포함)를 모아 내보내고, 새 DB에 복원했을 때
/// 리치서식과 휴지통 상태가 모두 살아있는지 확인한다.
void main() {
  test('live + trashed rich-text entry survives export → parse → restore', () async {
    const rich = '[{"insert":"F4J2VERIFY","attributes":{"bold":true}},{"insert":"\\n"}]';

    // 1) 소스 DB: 라이브 기록 1개 + 휴지통 기록 1개(리치서식 포함).
    final sourceDb = AppDatabase(NativeDatabase.memory());
    final sourceRepo = DiaryRepository(sourceDb);
    await sourceRepo.insert(DiaryEntry(
      entryId: 'live1',
      userId: 'me',
      journalId: 'jr_default',
      content: '평범한 라이브 기록',
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    ));
    await sourceRepo.insert(DiaryEntry(
      entryId: 'trashed1',
      userId: 'me',
      journalId: 'jr_default',
      content: 'F4J2VERIFY',
      contentRich: rich,
      createdAt: DateTime(2026, 6, 2),
      updatedAt: DateTime(2026, 6, 2),
    ));
    await sourceRepo.delete('trashed1'); // 휴지통으로 이동(소프트 삭제)

    // 설정 화면과 동일하게: 라이브 + 휴지통을 모두 모아 export.
    final live = await sourceRepo.getAll();
    final trashed = await sourceRepo.getTrashed();
    expect(live.map((e) => e.entryId), ['live1']);
    expect(trashed.map((e) => e.entryId), ['trashed1']);

    final json = exportBackupJson(
      const [],
      [...live, ...trashed],
      DateTime(2026, 6, 29),
    );
    await sourceDb.close();

    // 2) 새 기기(빈 DB)에서 복원.
    final data = parseBackupJson(json);
    expect(data.entries.length, 2);

    final targetDb = AppDatabase(NativeDatabase.memory());
    final targetRepo = DiaryRepository(targetDb);
    for (final e in data.entries) {
      await targetRepo.save(e);
    }

    final restoredLive = await targetRepo.getAll();
    final restoredTrash = await targetRepo.getTrashed();
    expect(restoredLive.map((e) => e.entryId), ['live1']);
    expect(restoredTrash.map((e) => e.entryId), ['trashed1']);
    expect(restoredTrash.first.contentRich, rich); // 리치서식 보존
    expect(restoredTrash.first.deletedAt, isNotNull); // 휴지통 상태 보존

    await targetDb.close();
  });
}
