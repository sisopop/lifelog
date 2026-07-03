import 'dart:convert';

/// Pure helpers for per-photo frame ids, index-aligned with
/// [DiaryEntry.mediaUrls]. A `null` entry (or an index past the end of the
/// list) means "no frame chosen" — mirrors the [flowPhotos]/[pageCanvas]
/// convention of never throwing on malformed/legacy input.

/// Decodes the JSON array stored in [DiaryEntry.photoFrames]. Non-string
/// elements become `null`. Malformed/blank input decodes to `[]`.
List<String?> decodePhotoFrames(String? json) {
  if (json == null || json.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(json);
    if (list is! List) return const [];
    return [for (final v in list) v is String ? v : null];
  } catch (_) {
    return const [];
  }
}

/// Encodes [frames], trimming trailing nulls so an entry with no frames
/// chosen serializes to `null` (keeps untouched records byte-identical).
String? encodePhotoFrames(List<String?> frames) {
  var end = frames.length;
  while (end > 0 && frames[end - 1] == null) {
    end--;
  }
  if (end == 0) return null;
  return jsonEncode(frames.sublist(0, end));
}

/// Safe index lookup; out-of-range and `null` both mean "no frame".
String? frameAt(List<String?> frames, int index) =>
    index >= 0 && index < frames.length ? frames[index] : null;

/// Pure setter: returns a new list with [index] set to [frameId], padding
/// with nulls as needed. Does not mutate [frames].
List<String?> withFrameAt(List<String?> frames, int index, String? frameId) {
  final next = List<String?>.of(frames);
  while (next.length <= index) {
    next.add(null);
  }
  next[index] = frameId;
  return next;
}
