/// 꾸미기(다꾸) — 일기장 표지 재질(질감) 소스 오브 트루스.
///
/// 가죽/크라프트/패브릭/코르크/우드 등 표지 '면'의 질감을 흑백 심리스 텍스처
/// 이미지(assets/textures/*.jpg)로 표현하고, 표지 색 위에 곱하기(multiply)로
/// 입혀 색은 유지한 채 결만 넣습니다(cover_texture_painter.dart). 이 파일은
/// 순수 Dart라 단위 테스트 가능 — 페인터/위젯/이미지 캐시는 이 값만 읽습니다.
library;

/// 재질 없음(매끈한 단색)을 뜻하는 id.
const String kDefaultCoverTexture = 'none';

/// 표지 재질 id 목록('none' 포함, 맨 앞).
const List<String> coverTexturePalette = [
  'none',
  'leather',
  'kraft',
  'fabric',
  'cork',
  'wood',
];

/// 재질 id → 한글 라벨(시트 칩 등에서 사용).
const Map<String, String> coverTextureLabels = {
  'none': '없음',
  'leather': '가죽',
  'kraft': '크라프트',
  'fabric': '패브릭',
  'cork': '코르크',
  'wood': '우드',
};

/// 알 수 없는/null 재질은 'none'으로 정규화.
String normalizeCoverTexture(String? id) {
  if (id == null || !coverTexturePalette.contains(id)) {
    return kDefaultCoverTexture;
  }
  return id;
}

/// 라벨 조회(없으면 id 그대로).
String coverTextureLabel(String id) => coverTextureLabels[id] ?? id;
