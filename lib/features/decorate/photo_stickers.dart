import 'dart:convert';

/// Pure helpers for the per-photo sticker list, mirroring photo_frames.dart:
/// a JSON array of nullable emoji strings, index-aligned with mediaUrls (a
/// `null` entry, or an index past the end, means no sticker for that photo).
/// null overall = no sticker chosen for any photo (byte-identical to records
/// created before this feature existed).
List<String?> decodePhotoStickers(String? json) {
  if (json == null || json.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(json);
    if (list is! List) return const [];
    return [for (final v in list) v is String ? v : null];
  } catch (_) {
    return const [];
  }
}

String? encodePhotoStickers(List<String?> stickers) {
  var end = stickers.length;
  while (end > 0 && stickers[end - 1] == null) {
    end--;
  }
  if (end == 0) return null;
  return jsonEncode(stickers.sublist(0, end));
}

String? stickerAt(List<String?> stickers, int index) =>
    index >= 0 && index < stickers.length ? stickers[index] : null;

List<String?> withStickerAt(
    List<String?> stickers, int index, String? emoji) {
  final next = List<String?>.of(stickers);
  while (next.length <= index) {
    next.add(null);
  }
  next[index] = emoji;
  return next;
}
