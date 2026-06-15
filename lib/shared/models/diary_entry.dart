import 'enums.dart';

/// Core diary record. Plain immutable model for the skeleton stage
/// (can be migrated to freezed + Drift later — see TECH_DESIGN.md).
class DiaryEntry {
  const DiaryEntry({
    required this.entryId,
    required this.userId,
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
    this.syncStatus = SyncStatus.synced,
  });

  final String entryId;
  final String userId;
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
  final SyncStatus syncStatus;

  DiaryEntry copyWith({
    String? title,
    String? content,
    String? aiSummary,
    AiStatus? aiStatus,
    Mood? mood,
    EntryVisibility? visibility,
    String? location,
    DateTime? updatedAt,
    List<String>? mediaUrls,
    List<String>? tags,
    SyncStatus? syncStatus,
  }) {
    return DiaryEntry(
      entryId: entryId,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      aiSummary: aiSummary ?? this.aiSummary,
      aiStatus: aiStatus ?? this.aiStatus,
      mood: mood ?? this.mood,
      visibility: visibility ?? this.visibility,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      tags: tags ?? this.tags,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
