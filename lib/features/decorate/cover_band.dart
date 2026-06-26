/// 꾸미기(다꾸) — 일기장 표지 밴드(스트랩) 소스 오브 트루스.
///
/// 닫힌 다이어리의 고무밴드/버클을 표지 위에 절차적(CustomPainter)으로 그립니다.
/// 비트맵 에셋이 없습니다. 순수 Dart라 단위 테스트 가능 — 위젯/페인터는 이 값만 읽습니다.
library;

/// 기본 밴드(없음) — 밴드 없음.
const String kDefaultCoverBand = 'none';

/// 꾸미기 v1 밴드 스타일 id 목록('none' 포함, 맨 앞).
const List<String> coverBandPalette = [
  'none',
  'band',
  'buckle',
  'double',
];

/// 밴드 id → 한글 라벨(시트 칩 등에서 사용).
const Map<String, String> coverBandLabels = {
  'none': '없음',
  'band': '밴드',
  'buckle': '버클',
  'double': '두줄',
};

/// 알 수 없는/null 밴드는 'none'으로 정규화.
String normalizeCoverBand(String? id) {
  if (id == null || !coverBandPalette.contains(id)) {
    return kDefaultCoverBand;
  }
  return id;
}

/// 라벨 조회(없으면 id 그대로).
String coverBandLabel(String id) => coverBandLabels[id] ?? id;
