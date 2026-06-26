/// 꾸미기(다꾸) — 일기장 제본 방식 소스 오브 트루스.
///
/// 책등(spine) 영역을 어떻게 그릴지를 정합니다. 전부 절차적(CustomPainter)이라
/// 비트맵 에셋이 없습니다. 순수 Dart라 단위 테스트 가능 — 위젯/페인터는 이 값만 읽습니다.
library;

/// 기본 제본(무선) — 단색 책등 띠.
const String kDefaultCoverBinding = 'plain';

/// 꾸미기 v1 제본 방식 id 목록('plain' 포함, 맨 앞).
const List<String> coverBindingPalette = [
  'plain',
  'spiral',
  'ring',
  'stitch',
  'staple',
  'disc',
];

/// 제본 id → 한글 라벨(시트 칩 등에서 사용).
const Map<String, String> coverBindingLabels = {
  'plain': '무선',
  'spiral': '스프링',
  'ring': '링',
  'stitch': '실제본',
  'staple': '중철',
  'disc': '디스크',
};

/// 알 수 없는/null 제본은 'plain'으로 정규화.
String normalizeCoverBinding(String? id) {
  if (id == null || !coverBindingPalette.contains(id)) {
    return kDefaultCoverBinding;
  }
  return id;
}

/// 라벨 조회(없으면 id 그대로).
String coverBindingLabel(String id) => coverBindingLabels[id] ?? id;
