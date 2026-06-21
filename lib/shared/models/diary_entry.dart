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
    this.isFavorite = false,
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

  /// User-starred record (즐겨찾기). Independent of journal/sync.
  final bool isFavorite;
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
    bool? isFavorite,
    SyncStatus? syncStatus,
    bool clearMood = false,
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
      isFavorite: isFavorite ?? this.isFavorite,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
