import 'enums.dart';

/// A journal (일기장) — the unit of grouping and sharing for entries.
/// See PRD.md §4 / TECH_DESIGN.md (journal-centric structure).
class Journal {
  const Journal({
    required this.journalId,
    required this.ownerId,
    required this.type,
    required this.title,
    this.coverColor = 0xFF7C6FF0,
    this.coverPattern = 'none',
    this.coverBinding = 'plain',
    this.coverCorner = 'none',
    this.coverBand = 'none',
    this.coverRibbon = 'none',
    this.coverClip = 'none',
    this.coverTab = 'none',
    this.coverTexture = 'none',
    this.coverFont = 'pretendard',
    this.innerPaper = 'plain',
    this.innerPaperColor = 'cream',
    this.icon,
    this.status = JournalStatus.active,
    this.spaceId,
    required this.createdAt,
  });

  final String journalId;
  final String ownerId;
  final JournalType type;
  final String title;

  /// ARGB int for the cover color.
  final int coverColor;

  /// Procedural cover pattern id ('none' = 단색). See cover_pattern.dart.
  final String coverPattern;

  /// 제본 방식 id ('plain' = 무선). See cover_binding.dart.
  final String coverBinding;

  /// 모서리 장식 id ('none' = 없음). See cover_corner.dart.
  final String coverCorner;

  /// 밴드(스트랩) id ('none' = 없음). See cover_band.dart.
  final String coverBand;

  /// 책갈피 리본 id ('none' = 없음). See cover_ribbon.dart.
  final String coverRibbon;

  /// 클립(페이퍼클립) id ('none' = 없음). See cover_clip.dart.
  final String coverClip;

  /// 우측 인덱스 탭 id ('none' = 없음). See cover_tab.dart.
  final String coverTab;

  /// 표지 재질(질감) id ('none' = 매끈한 단색). See cover_texture.dart.
  final String coverTexture;

  /// 제목 글꼴 id ('pretendard' = 앱 기본). See cover_font.dart.
  final String coverFont;

  /// 속지(내지) 종류 id ('plain' = 무지). 읽기 화면 배경에 반영. See cover_paper.dart.
  final String innerPaper;

  /// 속지 종이 바탕색 id ('cream' = 기본). 읽기 화면 배경색. See cover_paper_color.dart.
  final String innerPaperColor;

  /// Optional emoji icon; falls back to the type emoji when null.
  final String? icon;
  final JournalStatus status;

  /// Shared space id for couple/exchange journals (null for personal).
  final String? spaceId;
  final DateTime createdAt;

  String get displayIcon => icon ?? type.emoji;
  bool get isArchived => status == JournalStatus.ended;

  Journal copyWith({
    String? title,
    int? coverColor,
    String? coverPattern,
    String? coverBinding,
    String? coverCorner,
    String? coverBand,
    String? coverRibbon,
    String? coverClip,
    String? coverTab,
    String? coverTexture,
    String? coverFont,
    String? innerPaper,
    String? innerPaperColor,
    String? icon,
    JournalStatus? status,
    String? spaceId,
  }) {
    return Journal(
      journalId: journalId,
      ownerId: ownerId,
      type: type,
      title: title ?? this.title,
      coverColor: coverColor ?? this.coverColor,
      coverPattern: coverPattern ?? this.coverPattern,
      coverBinding: coverBinding ?? this.coverBinding,
      coverCorner: coverCorner ?? this.coverCorner,
      coverBand: coverBand ?? this.coverBand,
      coverRibbon: coverRibbon ?? this.coverRibbon,
      coverClip: coverClip ?? this.coverClip,
      coverTab: coverTab ?? this.coverTab,
      coverTexture: coverTexture ?? this.coverTexture,
      coverFont: coverFont ?? this.coverFont,
      innerPaper: innerPaper ?? this.innerPaper,
      innerPaperColor: innerPaperColor ?? this.innerPaperColor,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      spaceId: spaceId ?? this.spaceId,
      createdAt: createdAt,
    );
  }
}
