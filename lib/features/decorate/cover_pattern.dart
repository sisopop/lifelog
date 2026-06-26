/// 꾸미기(다꾸) — 일기장 표지 패턴 소스 오브 트루스.
///
/// 전부 절차적(CustomPainter)으로 그리므로 비트맵 에셋이 없습니다.
/// 순수 Dart라서 단위 테스트 가능 — 위젯/페인터는 이 값만 읽습니다.
library;

/// 패턴 없음(단색)을 뜻하는 id.
const String kNoCoverPattern = 'none';

/// 꾸미기 v1 표지 패턴 id 목록('none' 포함, 맨 앞).
const List<String> coverPatternPalette = [
  'none',
  'dots',
  'grid',
  'stripes',
  'diagonal',
  'checks',
  'waves',
  'hearts',
];

/// 패턴 id → 한글 라벨(시트 칩 등에서 사용).
const Map<String, String> coverPatternLabels = {
  'none': '없음',
  'dots': '도트',
  'grid': '모눈',
  'stripes': '줄무늬',
  'diagonal': '대각선',
  'checks': '체크',
  'waves': '물결',
  'hearts': '하트',
};

/// 알 수 없는/null 패턴은 'none'으로 정규화.
String normalizeCoverPattern(String? id) {
  if (id == null || !coverPatternPalette.contains(id)) return kNoCoverPattern;
  return id;
}

/// 라벨 조회(없으면 id 그대로).
String coverPatternLabel(String id) => coverPatternLabels[id] ?? id;
