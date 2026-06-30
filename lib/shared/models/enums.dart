/// Emotion attached to a diary entry.
enum Mood {
  good('좋았어요', '😊'),
  neutral('보통', '😐'),
  hard('힘들었어요', '😔');

  const Mood(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Result of tapping a mood chip: tapping the already-selected mood clears it
/// (returns null), tapping a different one selects it. Lets the writer undo a
/// mis-tapped mood without a separate clear button. Pure & top-level so it is
/// unit-testable; the write screen assigns the result to its mood field.
Mood? toggledMood(Mood? current, Mood tapped) =>
    current == tapped ? null : tapped;

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

/// Journal kind. A journal is the sharing unit (see TECH_DESIGN.md).
/// personal: 개인(나만), couple: 둘만의 일기장, exchange: 친구와 교환.
enum JournalType {
  personal('개인', '📔'),
  couple('커플', '💞'),
  exchange('교환', '🔁');

  const JournalType(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Lifecycle of a journal. ended = 읽기전용 아카이브(커플 종료 등), hidden = 숨김.
enum JournalStatus { active, ended, hidden }

/// Role of a participant in a shared journal (couple/exchange).
/// owner = 만든 사람, partner = 초대로 합류한 사람.
enum MemberRole { owner, partner }

/// Media attachment type.
enum MediaType { image, audio }

/// Local sync status for local-first cache.
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

/// AI summary generation status.
enum AiStatus { none, pending, done, failed }
