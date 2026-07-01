import 'enums.dart';

/// Core diary record. Plain immutable model for the skeleton stage
/// (can be migrated to freezed + Drift later — see TECH_DESIGN.md).
class DiaryEntry {
  const DiaryEntry({
    required this.entryId,
    required this.userId,
    required this.journalId,
    this.replyToEntryId,
    this.lang = 'ko',
    this.title,
    required this.content,
    this.aiSummary,
    this.aiStatus = AiStatus.none,
    this.mood,
    this.visibility = EntryVisibility.private,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.mediaUrls = const [],
    this.tags = const [],
    this.pageCanvas,
    this.flowPhotos,
    this.isFavorite = false,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  final String entryId;
  final String userId;

  /// Owning journal (일기장). Required — every entry belongs to a journal.
  final String journalId;

  /// 답장형 기록: the entry this one replies to (null for top-level entries).
  final String? replyToEntryId;

  /// Original authoring language (ko/en/ja...). Used as the source for the
  /// on-demand "번역 보기" feature in the global phase (see TECH_DESIGN.md §8).
  final String lang;
  final String? title;
  final String content;
  final String? aiSummary;
  final AiStatus aiStatus;
  final Mood? mood;
  final EntryVisibility visibility;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> mediaUrls;
  final List<String> tags;

  /// 페이지(내지) 꾸미기 캔버스의 JSON 직렬화 문자열. null이면 꾸미기 없는
  /// 순수 텍스트 기록(종전과 동일). 본문 [content]와 별도로 보관된다.
  final String? pageCanvas;

  /// 본문 흐름에 끼운 인라인 사진들(글을 위/아래로 나누는 전체폭 블록)의 JSON
  /// 배열 문자열. null이면 끼운 사진 없음. 본문 [content]는 그대로 유지된다.
  final String? flowPhotos;

  /// User-starred record (즐겨찾기). Independent of journal/sync.
  final bool isFavorite;

  /// 휴지통: when non-null, the entry is soft-deleted (kept 30 days, hidden
  /// from every normal list). Restoring clears it back to null.
  final DateTime? deletedAt;
  final SyncStatus syncStatus;

  DiaryEntry copyWith({
    String? journalId,
    String? replyToEntryId,
    String? lang,
    String? title,
    String? content,
    String? aiSummary,
    AiStatus? aiStatus,
    Mood? mood,
    EntryVisibility? visibility,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? mediaUrls,
    List<String>? tags,
    String? pageCanvas,
    String? flowPhotos,
    bool? isFavorite,
    DateTime? deletedAt,
    SyncStatus? syncStatus,
    bool clearMood = false,
    bool clearDeletedAt = false,
    bool clearPageCanvas = false,
    bool clearFlowPhotos = false,
  }) {
    return DiaryEntry(
      entryId: entryId,
      userId: userId,
      journalId: journalId ?? this.journalId,
      replyToEntryId: replyToEntryId ?? this.replyToEntryId,
      lang: lang ?? this.lang,
      title: title ?? this.title,
      content: content ?? this.content,
      aiSummary: aiSummary ?? this.aiSummary,
      aiStatus: aiStatus ?? this.aiStatus,
      mood: clearMood ? null : (mood ?? this.mood),
      visibility: visibility ?? this.visibility,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      tags: tags ?? this.tags,
      pageCanvas: clearPageCanvas ? null : (pageCanvas ?? this.pageCanvas),
      flowPhotos: clearFlowPhotos ? null : (flowPhotos ?? this.flowPhotos),
      isFavorite: isFavorite ?? this.isFavorite,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
