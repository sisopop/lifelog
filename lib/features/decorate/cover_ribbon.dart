/// 꾸미기(다꾸) — 일기장 표지 책갈피 리본(북마크) 소스 오브 트루스.
///
/// 표지 윗변에서 아래로 늘어진 책갈피 리본을 절차적(CustomPainter)으로 그립니다.
/// 비트맵 에셋이 없습니다. 순수 Dart라 단위 테스트 가능 — 위젯/페인터는 이 값만 읽습니다.
library;

/// 기본 리본(없음) — 리본 없음.
const String kDefaultCoverRibbon = 'none';

/// 꾸미기 v1 리본 색상 id 목록('none' 포함, 맨 앞).
const List<String> coverRibbonPalette = [
  'none',
  'red',
  'gold',
  'pink',
];

/// 리본 id → 한글 라벨(시트 칩 등에서 사용).
const Map<String, String> coverRibbonLabels = {
  'none': '없음',
  'red': '빨강',
  'gold': '골드',
  'pink': '핑크',
};

/// 리본 id → ARGB 색상(페인터에서 사용). 'none'은 포함하지 않음.
const Map<String, int> coverRibbonColors = {
  'red': 0xFFE0584F,
  'gold': 0xFFE6B85C,
  'pink': 0xFFEE89B3,
};

/// 알 수 없는/null 리본은 'none'으로 정규화.
String normalizeCoverRibbon(String? id) {
  if (id == null || !coverRibbonPalette.contains(id)) {
    return kDefaultCoverRibbon;
  }
  return id;
}

/// 라벨 조회(없으면 id 그대로).
String coverRibbonLabel(String id) => coverRibbonLabels[id] ?? id;
