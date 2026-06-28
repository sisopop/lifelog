/// 휴지통 보관 정책: soft-delete 후 [trashRetentionDays]일이 지나면 영구 삭제된다.
const trashRetentionDays = 30;

/// [deletedAt]로부터 영구 삭제까지 남은 일수를 0~[trashRetentionDays]로 고정해 반환한다.
///
/// 경과 일수는 달력 차이의 내림(`Duration.inDays`)으로 센다. 정확히 30일이
/// 지나면 0(곧 삭제), 아직 삭제 시각이 미래면(이상치) 최대 30으로 막는다.
int daysUntilPurge(DateTime deletedAt, DateTime now) {
  final elapsed = now.difference(deletedAt).inDays;
  final left = trashRetentionDays - elapsed;
  if (left < 0) return 0;
  if (left > trashRetentionDays) return trashRetentionDays;
  return left;
}

/// 남은 일수를 사람이 읽는 한 줄 라벨로. 0이면 "곧 삭제돼요".
String trashRetentionLabel(DateTime deletedAt, DateTime now) {
  final left = daysUntilPurge(deletedAt, now);
  return left <= 0 ? '곧 삭제돼요' : '$left일 후 삭제';
}
