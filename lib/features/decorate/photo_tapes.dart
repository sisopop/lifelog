import 'dart:convert';

/// Pure helpers for the per-photo washi-tape list, mirroring photo_stickers.dart:
/// a JSON array of nullable tape-id strings (see washi_tape_catalog.dart),
/// index-aligned with mediaUrls (a `null` entry, or an index past the end,
/// means no tape for that photo). null overall = no tape chosen for any photo
/// (byte-identical to records created before this feature existed).
List<String?> decodePhotoTapes(String? json) {
  if (json == null || json.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(json);
    if (list is! List) return const [];
    return [for (final v in list) v is String ? v : null];
  } catch (_) {
    return const [];
  }
}

String? encodePhotoTapes(List<String?> tapes) {
  var end = tapes.length;
  while (end > 0 && tapes[end - 1] == null) {
    end--;
  }
  if (end == 0) return null;
  return jsonEncode(tapes.sublist(0, end));
}

String? tapeAt(List<String?> tapes, int index) =>
    index >= 0 && index < tapes.length ? tapes[index] : null;

List<String?> withTapeAt(List<String?> tapes, int index, String? tapeId) {
  final next = List<String?>.of(tapes);
  while (next.length <= index) {
    next.add(null);
  }
  next[index] = tapeId;
  return next;
}
