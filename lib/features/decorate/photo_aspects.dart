import 'dart:convert';

/// Pure helpers for the per-photo display-aspect choice, mirroring
/// photo_memos.dart / photo_tapes.dart: a JSON array of nullable id strings,
/// index-aligned with mediaUrls (a `null` entry, or an index past the end,
/// means "원본" — no forced ratio, so the read gallery uses the photo's natural
/// shape). null overall = no ratio chosen for any photo (byte-identical to
/// records created before this feature existed).
///
/// The stored id is one of [kPhotoAspectChoices]; any blank/unknown value
/// normalises to `null` (원본) so a stray string never sticks.

/// A selectable display ratio for one photo. [id] is what persists; [ratio] is
/// the `width / height` the read gallery clamps its box to (null = 원본, i.e.
/// keep the photo's natural ratio — see galleryAspectRatio).
class PhotoAspectChoice {
  const PhotoAspectChoice(this.id, this.label, this.ratio);

  final String id;
  final String label;
  final double? ratio;
}

/// The pickable ratios. "원본" is represented by a `null` stored value (not an
/// id), so it is intentionally absent here; the picker offers it separately.
const List<PhotoAspectChoice> kPhotoAspectChoices = [
  PhotoAspectChoice('square', '1:1', 1.0),
  PhotoAspectChoice('wide', '4:3', 4 / 3),
  PhotoAspectChoice('tall', '3:4', 3 / 4),
];

/// Maps a stored aspect id to the box ratio (`width / height`) the gallery
/// should force. `null`/blank/'original'/unknown → `null` = keep natural ratio.
double? aspectRatioForChoice(String? choice) {
  if (choice == null || choice.trim().isEmpty) return null;
  for (final c in kPhotoAspectChoices) {
    if (c.id == choice) return c.ratio;
  }
  return null;
}

List<String?> decodePhotoAspects(String? json) {
  if (json == null || json.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(json);
    if (list is! List) return const [];
    return [
      for (final v in list)
        v is String && aspectRatioForChoice(v) != null ? v : null,
    ];
  } catch (_) {
    return const [];
  }
}

String? encodePhotoAspects(List<String?> aspects) {
  var end = aspects.length;
  while (end > 0 && aspectRatioForChoice(aspects[end - 1]) == null) {
    end--;
  }
  if (end == 0) return null;
  return jsonEncode([
    for (final a in aspects.sublist(0, end))
      aspectRatioForChoice(a) != null ? a : null,
  ]);
}

String? aspectAt(List<String?> aspects, int index) =>
    index >= 0 && index < aspects.length ? aspects[index] : null;

List<String?> withAspectAt(List<String?> aspects, int index, String? id) {
  final normalized = aspectRatioForChoice(id) != null ? id : null;
  final next = List<String?>.of(aspects);
  while (next.length <= index) {
    next.add(null);
  }
  next[index] = normalized;
  return next;
}
