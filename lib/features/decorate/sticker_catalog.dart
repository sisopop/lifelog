// 페이지 꾸미기용 기본 스티커(이모지) 카탈로그.
//
// 외부 이미지 자산 없이도 곧바로 "꾸미는 재미"를 줄 수 있도록 이모지로 구성했다
// (추후 이미지/PNG 스티커 팩으로 확장 가능). 카테고리별로 묶어 팔레트 탭에
// 그대로 노출한다. 순수 데이터라 단위 테스트로 검증한다.

/// 한 묶음의 스티커(팔레트 탭 하나에 대응).
class StickerCategory {
  const StickerCategory(this.id, this.label, this.stickers);
  final String id;
  final String label;
  final List<String> stickers;
}

/// 선택 가능한 스티커 카탈로그. 첫 카테고리가 팔레트에서 기본 선택된다.
const List<StickerCategory> kStickerCatalog = [
  // 기분/food 카테고리의 🥰·🥳·🧁는 2018년(유니코드 11.0)에 추가된 이모지라
  // 구형 기기(예: 삼성 갤럭시 A5 2017)의 시스템 폰트가 못 그려 검은 사각형으로
  // 깨져 보이는 문제가 있어, 훨씬 오래되고 폭넓게 지원되는 이모지로 교체했다.
  StickerCategory('feeling', '기분', [
    '😊', '😍', '😘', '😢', '😡', '😴', '🤔', '😎', '🎉', '😭',
  ]),
  StickerCategory('nature', '자연', [
    '🌸', '🌷', '🌻', '🌿', '🍀', '🌙', '⭐', '☀️', '🌈', '❄️',
  ]),
  StickerCategory('food', '먹부림', [
    '🍰', '🍓', '☕', '🍔', '🍜', '🍦', '🍪', '🥑', '🍉', '🍩',
  ]),
  StickerCategory('life', '일상', [
    '❤️', '✨', '🎀', '📌', '✅', '🔥', '💡', '🎵', '📷', '🎁',
  ]),
];

/// 모든 스티커를 카탈로그 순서대로 한 줄로 펼친다(중복 없음 보장은 테스트가 검증).
List<String> allStickers() => [
      for (final category in kStickerCatalog) ...category.stickers,
    ];
