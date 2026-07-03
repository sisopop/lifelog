import 'dart:convert';

/// Pure helpers for the per-photo memo (caption) list, mirroring
/// photo_tapes.dart: a JSON array of nullable caption strings, index-aligned
/// with mediaUrls (a `null` entry, or an index past the end, means no memo for
/// that photo). null overall = no memo written for any photo (byte-identical to
/// records created before this feature existed). Blank/whitespace-only captions
/// are normalised to `null` so an empty note never persists.
List<String?> decodePhotoMemos(String? json) {
  if (json == null || json.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(json);
    if (list is! List) return const [];
    return [
      for (final v in list)
        v is String && v.trim().isNotEmpty ? v : null,
    ];
  } catch (_) {
    return const [];
  }
}

String? encodePhotoMemos(List<String?> memos) {
  var end = memos.length;
  while (end > 0 && (memos[end - 1] == null || memos[end - 1]!.trim().isEmpty)) {
    end--;
  }
  if (end == 0) return null;
  return jsonEncode([
    for (final m in memos.sublist(0, end))
      (m != null && m.trim().isNotEmpty) ? m : null,
  ]);
}

String? memoAt(List<String?> memos, int index) =>
    index >= 0 && index < memos.length ? memos[index] : null;

List<String?> withMemoAt(List<String?> memos, int index, String? memo) {
  final trimmed = (memo != null && memo.trim().isNotEmpty) ? memo.trim() : null;
  final next = List<String?>.of(memos);
  while (next.length <= index) {
    next.add(null);
  }
  next[index] = trimmed;
  return next;
}
