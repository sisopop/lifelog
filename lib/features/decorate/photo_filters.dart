import 'dart:convert';

/// Pure helpers for the per-photo colour filter (사진 효과), mirroring
/// photo_aspects.dart / photo_memos.dart: a JSON array of nullable id strings,
/// index-aligned with mediaUrls (a `null` entry, or an index past the end,
/// means "원본" — no filter, the photo's own colours). null overall = no filter
/// chosen for any photo (byte-identical to records created before this feature).
///
/// The stored id is one of [kPhotoFilterChoices]; any blank/unknown value
/// normalises to `null` (원본) so a stray string never sticks. The read/edit
/// widgets turn a chosen id into a 5×4 colour matrix via [colorMatrixForChoice]
/// and wrap the photo in a `ColorFiltered(ColorFilter.matrix(...))`.

/// A selectable colour filter for one photo. [id] is what persists; [matrix] is
/// the 20-element (5×4) colour matrix the widget feeds to `ColorFilter.matrix`.
class PhotoFilterChoice {
  const PhotoFilterChoice(this.id, this.label, this.matrix);

  final String id;
  final String label;
  final List<double> matrix;
}

/// The pickable filters. "원본" is represented by a `null` stored value (not an
/// id), so it is intentionally absent here; the picker offers it separately.
const List<PhotoFilterChoice> kPhotoFilterChoices = [
  // Luminance-weighted greyscale.
  PhotoFilterChoice('mono', '흑백', [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]),
  // Classic sepia tone.
  PhotoFilterChoice('sepia', '세피아', [
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0, //
    0.272, 0.534, 0.131, 0, 0, //
    0, 0, 0, 1, 0, //
  ]),
  // Warm: lift red, ease blue.
  PhotoFilterChoice('warm', '따뜻', [
    1.1, 0, 0, 0, 12, //
    0, 1.0, 0, 0, 0, //
    0, 0, 0.9, 0, -12, //
    0, 0, 0, 1, 0, //
  ]),
  // Cool: lift blue, ease red.
  PhotoFilterChoice('cool', '시원', [
    0.9, 0, 0, 0, -12, //
    0, 1.0, 0, 0, 0, //
    0, 0, 1.1, 0, 12, //
    0, 0, 0, 1, 0, //
  ]),
];

/// Maps a stored filter id to its 5×4 colour matrix. `null`/blank/unknown →
/// `null` = 원본 (no filter, keep the photo's own colours).
List<double>? colorMatrixForChoice(String? choice) {
  if (choice == null || choice.trim().isEmpty) return null;
  for (final c in kPhotoFilterChoices) {
    if (c.id == choice) return c.matrix;
  }
  return null;
}

List<String?> decodePhotoFilters(String? json) {
  if (json == null || json.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(json);
    if (list is! List) return const [];
    return [
      for (final v in list)
        v is String && colorMatrixForChoice(v) != null ? v : null,
    ];
  } catch (_) {
    return const [];
  }
}

String? encodePhotoFilters(List<String?> filters) {
  var end = filters.length;
  while (end > 0 && colorMatrixForChoice(filters[end - 1]) == null) {
    end--;
  }
  if (end == 0) return null;
  return jsonEncode([
    for (final f in filters.sublist(0, end))
      colorMatrixForChoice(f) != null ? f : null,
  ]);
}

String? filterAt(List<String?> filters, int index) =>
    index >= 0 && index < filters.length ? filters[index] : null;

List<String?> withFilterAt(List<String?> filters, int index, String? id) {
  final normalized = colorMatrixForChoice(id) != null ? id : null;
  final next = List<String?>.of(filters);
  while (next.length <= index) {
    next.add(null);
  }
  next[index] = normalized;
  return next;
}
