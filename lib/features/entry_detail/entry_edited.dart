import '../../shared/models/diary_entry.dart';

/// Sub-minute gaps between create and update are just save jitter, not a
/// real edit, so we ignore anything under this threshold.
const _editThreshold = Duration(minutes: 1);

/// Pure: whether [entry] has been meaningfully edited after creation
/// (updatedAt is at least a minute later than createdAt).
bool wasEdited(DiaryEntry entry) {
  return entry.updatedAt.difference(entry.createdAt) >= _editThreshold;
}
