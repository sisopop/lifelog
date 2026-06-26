/// 꾸미기(다꾸) — 일기장 표지 클립(페이퍼클립) 소스 오브 트루스.
///
/// 표지 윗변에 꽂힌 금속 클립을 절차적(CustomPainter)으로 그립니다.
/// 비트맵 에셋이 없습니다. 순수 Dart라 단위 테스트 가능 — 위젯/페인터는 이 값만 읽습니다.
library;

/// 기본 클립(없음) — 클립 없음.
const String kDefaultCoverClip = 'none';

/// 꾸미기 v1 클립 색상 id 목록('none' 포함, 맨 앞).
const List<String> coverClipPalette = [
  'none',
  'silver',
  'gold',
  'pink',
];

/// 클립 id → 한글 라벨(시트 칩 등에서 사용).
const Map<String, String> coverClipLabels = {
  'none': '없음',
  'silver': '실버',
  'gold': '골드',
  'pink': '핑크',
};

/// 클립 id → ARGB 색상(페인터에서 사용). 'none'은 포함하지 않음.
const Map<String, int> coverClipColors = {
  'silver': 0xFFB9BEC7,
  'gold': 0xFFE6B85C,
  'pink': 0xFFEE89B3,
};

/// 알 수 없는/null 클립은 'none'으로 정규화.
String normalizeCoverClip(String? id) {
  if (id == null || !coverClipPalette.contains(id)) {
    return kDefaultCoverClip;
  }
  return id;
}

/// 라벨 조회(없으면 id 그대로).
String coverClipLabel(String id) => coverClipLabels[id] ?? id;
