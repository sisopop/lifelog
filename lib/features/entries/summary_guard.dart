/// ARCHITECTURE_RISK_REVIEW F4 수정: AI 요약 응답이 늦게 도착했을 때, 그 사이
/// 사용자가 본문을 수정하거나 기록을 휴지통/영구삭제로 옮겼다면 그 결과를
/// 되돌리지 않도록 막는 순수 판정 함수.
///
/// [snapshotUpdatedAt]는 요약을 요청한 시점의 `updatedAt`(스냅샷),
/// [currentUpdatedAt]/[currentDeletedAt]은 지금 DB에 실제로 있는 값이다.
/// 기록이 영구 삭제되어 존재하지 않으면 [currentUpdatedAt]에 null을 넘긴다.
bool canApplyAiSummary({
  required DateTime snapshotUpdatedAt,
  required DateTime? currentUpdatedAt,
  required DateTime? currentDeletedAt,
}) {
  if (currentUpdatedAt == null) return false; // 영구 삭제됨
  if (currentDeletedAt != null) return false; // 휴지통으로 이동함
  return currentUpdatedAt.isAtSameMomentAs(snapshotUpdatedAt);
}
