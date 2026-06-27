/// 꾸미기(다꾸) — 일기장 표지 꾸미기에 쓰는 색 팔레트 소스 오브 트루스.
///
/// v1은 단색/절차적 색상만 다룹니다. 일러스트 팩은 후속 단계.
/// 순수 Dart라서 단위 테스트 가능 — 위젯은 이 값만 읽어서 그립니다.
library;

/// 기본 표지색 (Journal.coverColor 기본값과 동일).
const int kDefaultCoverColor = 0xFF7C6FF0;

/// 꾸미기 v1 표지색 프리셋. 모두 불투명(alpha 0xFF) ARGB.
const List<int> coverColorPalette = [
  0xFF7C6FF0, // 보라
  0xFFEF6F9E, // 핑크
  0xFF53B7A8, // 민트
  0xFFF0A35E, // 살구
  0xFF6FA8F0, // 하늘
  0xFF9B6FF0, // 라벤더
  0xFFF06F6F, // 코랄
  0xFFF0C26F, // 머스터드
  0xFF6FC97A, // 그린
  0xFF6F8AF0, // 블루
  0xFFB76FF0, // 자주
  0xFF4A4A5A, // 차콜
];

/// 편집기에 표시할 팔레트를 돌려줍니다. [current]가 프리셋에 없으면
/// (예: 예전 타입 기본색) 맨 앞에 끼워 넣어 "선택됨"으로 보이게 합니다.
/// 중복은 만들지 않습니다.
List<int> coverPaletteFor(int current) {
  if (coverColorPalette.contains(current)) return coverColorPalette;
  return [current, ...coverColorPalette];
}

/// "아이콘 없음" 센티넬. 빈 문자열을 저장하면 displayIcon이 빈 문자열을
/// 돌려주므로(타입 기본 이모지로 폴백하지 않음) 표지에 아이콘이 안 보입니다.
const String kNoCoverIcon = '';

/// 꾸미기 v1.5 표지 아이콘(이모지) 프리셋.
const List<String> coverIconPalette = [
  '📔', '📖', '📒', '✏️', '🌙', '⭐', '🌸', '🍀',
  '☕', '🐱', '🎀', '🔥',
];

/// 편집기에 표시할 아이콘 팔레트를 돌려줍니다. 맨 앞에 "없음"(빈 문자열)을
/// 항상 끼우고, 현재 아이콘이 프리셋에 없으면(예: 타입 기본 이모지) 그다음에
/// 끼워 "선택됨"으로 보이게 합니다. 중복 없음.
List<String> coverIconPaletteFor(String current) {
  final base = [kNoCoverIcon, ...coverIconPalette];
  if (base.contains(current)) return base;
  return [base.first, current, ...coverIconPalette];
}
