/// Emotion attached to a diary entry.
enum Mood {
  good('좋았어요', '😊'),
  neutral('보통', '😐'),
  hard('힘들었어요', '😔');

  const Mood(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Sharing scope. MVP supports private / link / public.
/// Named `EntryVisibility` to avoid clashing with Flutter's `Visibility` widget.
enum EntryVisibility {
  private('나만 보기', '🔒'),
  link('링크 공유', '🔗'),
  public('전체 공개', '🌐');

  const EntryVisibility(this.label, this.icon);
  final String label;
  final String icon;
}

/// Media attachment type.
enum MediaType { image, audio }

/// Local sync status for local-first cache.
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

/// AI summary generation status.
enum AiStatus { none, pending, done, failed }
