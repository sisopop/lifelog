/// 꾸미기 — 일기장 표지 "제목 글꼴" 소스 오브 트루스.
///
/// 순수 Dart라서 단위 테스트 가능 — 위젯은 이 값만 읽어서 그립니다.
/// 글꼴 파일은 pubspec.yaml에 등록(OFL): Jua/DoHyeon/Gaegu.
library;

/// 기본 제목 글꼴 id(앱 기본 Pretendard). [coverFontFamily]가 null을 돌려줘
/// 위젯이 테마 기본 글꼴(Pretendard)을 그대로 쓰게 합니다.
const String kDefaultCoverFont = 'pretendard';

/// 표지 제목 글꼴 한 종.
class CoverFont {
  const CoverFont(this.id, this.label, this.family);

  /// 저장용 안정 id(예: 'jua'). DB의 coverFont 컬럼에 들어갑니다.
  final String id;

  /// 피커에 표시할 한글 라벨.
  final String label;

  /// Flutter fontFamily 이름. null이면 앱 기본 글꼴(Pretendard).
  final String? family;
}

/// 표지 제목 글꼴 프리셋. 첫 항목은 항상 기본(Pretendard).
const List<CoverFont> coverFontPalette = [
  CoverFont(kDefaultCoverFont, '기본', null),
  CoverFont('jua', '둥근', 'Jua'),
  CoverFont('dohyeon', '굵은', 'DoHyeon'),
  CoverFont('gaegu', '손글씨', 'Gaegu'),
];

/// 알 수 없는 id(예: 구버전/오염값)는 기본으로 폴백합니다.
String normalizeCoverFont(String id) {
  for (final f in coverFontPalette) {
    if (f.id == id) return id;
  }
  return kDefaultCoverFont;
}

/// 제목 Text에 줄 fontFamily. 기본이면 null(테마 글꼴 사용).
String? coverFontFamily(String id) {
  for (final f in coverFontPalette) {
    if (f.id == id) return f.family;
  }
  return null;
}

/// 피커 라벨.
String coverFontLabel(String id) {
  for (final f in coverFontPalette) {
    if (f.id == id) return f.label;
  }
  return coverFontPalette.first.label;
}
