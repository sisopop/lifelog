import '../../shared/models/journal.dart';

/// 표지 테마 프리셋 — 여러 꾸미기 레이어(색·아이콘·재질·제본·모서리·밴드·
/// 책갈피·클립·탭)를 한 번에 적용하는 "조합" 단위. 새 엔진/DB 컬럼 없이
/// 이미 만든 레이어 값을 묶어 한 탭으로 분위기를 바꾼다(절차적·무료).
class CoverTheme {
  const CoverTheme({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.texture = 'none',
    this.binding = 'plain',
    this.corner = 'none',
    this.band = 'none',
    this.ribbon = 'none',
    this.clip = 'none',
    this.tab = 'none',
  });

  final String id;
  final String label; // 한글 표시 이름
  final String icon; // 표지 이모지
  final int color; // ARGB
  final String texture;
  final String binding;
  final String corner;
  final String band;
  final String ribbon;
  final String clip;
  final String tab;
}

/// 기본 제공 테마 4종. 각 레이어 id는 해당 cover_*.dart 팔레트의 유효 값만 사용.
const List<CoverTheme> coverThemes = [
  CoverTheme(
    id: 'vintage',
    label: '빈티지',
    icon: '☕',
    color: 0xFF4A4A5A, // 차콜
    texture: 'leather',
    binding: 'stitch',
    corner: 'fold',
    band: 'buckle',
    ribbon: 'gold',
    clip: 'gold',
  ),
  CoverTheme(
    id: 'natural',
    label: '내추럴',
    icon: '🍀',
    color: 0xFF6FC97A, // 그린
    texture: 'kraft',
    binding: 'disc',
    corner: 'tape',
    clip: 'silver',
  ),
  CoverTheme(
    id: 'lovely',
    label: '러블리',
    icon: '🎀',
    color: 0xFFEF6F9E, // 핑크
    texture: 'fabric',
    binding: 'spiral',
    ribbon: 'pink',
    clip: 'pink',
    tab: 'pink',
  ),
  CoverTheme(
    id: 'woody',
    label: '우디',
    icon: '🔥',
    color: 0xFFF0A35E, // 살구
    texture: 'wood',
    binding: 'ring',
    band: 'band',
    corner: 'photo',
  ),
];

/// Pure: [theme]의 모든 레이어 값을 [j]에 적용한 새 Journal을 돌려준다.
/// 패턴은 'none'으로 초기화해 테마가 깔끔하게 덮어쓰도록 한다.
Journal applyCoverTheme(Journal j, CoverTheme theme) {
  return j.copyWith(
    coverColor: theme.color,
    icon: theme.icon,
    coverTexture: theme.texture,
    coverBinding: theme.binding,
    coverCorner: theme.corner,
    coverBand: theme.band,
    coverRibbon: theme.ribbon,
    coverClip: theme.clip,
    coverTab: theme.tab,
    coverPattern: 'none',
  );
}
