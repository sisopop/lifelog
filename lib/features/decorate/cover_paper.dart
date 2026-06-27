/// 속지(내지) 종류 — 일기 읽기 화면 배경에 깔리는 종이 스타일.
///
/// 표지 레이어들과 같은 패턴: 순수 팔레트/정규화/라벨만 두고,
/// 실제 그리기는 cover_paper_painter.dart의 PaperPainter가 담당한다.
/// 'plain'(무지)은 선을 그리지 않아 기존 읽기 화면과 동일하게 보인다.
library;

/// 기본 속지 id. 'plain' = 무지(선 없음).
const String kDefaultCoverPaper = 'plain';

/// 하나의 속지 프리셋.
class CoverPaper {
  const CoverPaper(this.id, this.label);
  final String id;
  final String label;
}

/// 선택 가능한 속지 목록. 첫 항목은 항상 기본(무지).
/// lined = 가로줄만(여백선 없음), ruled = 가로줄 + 왼쪽 세로 여백선 하나(줄노트),
/// grid = 모눈, dot = 도트.
const List<CoverPaper> coverPaperPalette = [
  CoverPaper(kDefaultCoverPaper, '무지'),
  CoverPaper('lined', '가로줄'),
  CoverPaper('ruled', '줄노트'),
  CoverPaper('grid', '모눈'),
  CoverPaper('dot', '도트'),
];

/// 알 수 없는 id는 기본(무지)으로 폴백한다.
String normalizeCoverPaper(String id) =>
    coverPaperPalette.any((p) => p.id == id) ? id : kDefaultCoverPaper;

/// id의 한글 라벨. 알 수 없는 id는 기본 라벨을 돌려준다.
String coverPaperLabel(String id) {
  for (final p in coverPaperPalette) {
    if (p.id == id) return p.label;
  }
  return coverPaperPalette.first.label;
}
