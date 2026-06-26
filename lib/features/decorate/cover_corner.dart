/// 꾸미기(다꾸) — 일기장 표지 모서리 장식 소스 오브 트루스.
///
/// 표지 네 귀퉁이에 절차적(CustomPainter)으로 장식을 얹습니다. 비트맵 에셋이
/// 없습니다. 순수 Dart라 단위 테스트 가능 — 위젯/페인터는 이 값만 읽습니다.
library;

/// 기본 모서리 장식(없음) — 깔끔한 모서리.
const String kDefaultCoverCorner = 'none';

/// 꾸미기 v1 모서리 장식 id 목록('none' 포함, 맨 앞).
const List<String> coverCornerPalette = [
  'none',
  'photo',
  'tape',
  'fold',
];

/// 모서리 장식 id → 한글 라벨(시트 칩 등에서 사용).
const Map<String, String> coverCornerLabels = {
  'none': '없음',
  'photo': '포토',
  'tape': '테이프',
  'fold': '접지',
};

/// 알 수 없는/null 장식은 'none'으로 정규화.
String normalizeCoverCorner(String? id) {
  if (id == null || !coverCornerPalette.contains(id)) {
    return kDefaultCoverCorner;
  }
  return id;
}

/// 라벨 조회(없으면 id 그대로).
String coverCornerLabel(String id) => coverCornerLabels[id] ?? id;
