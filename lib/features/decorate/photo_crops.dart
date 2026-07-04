import 'dart:convert';

import 'package:flutter/painting.dart' show Alignment;

/// Pure helpers for the per-photo crop position (크롭 위치), mirroring
/// photo_aspects.dart / photo_filters.dart: a JSON array of nullable id strings,
/// index-aligned with mediaUrls (a `null` entry, or an index past the end,
/// means "중앙" — centre crop, exactly how the gallery behaved before this
/// feature). null overall = no crop position chosen for any photo
/// (byte-identical to records created before this feature existed).
///
/// A photo shown in a box of a different ratio than its own is cropped with
/// `BoxFit.cover`; this choice decides which part survives — top/bottom for a
/// tall photo in a wide box, left/right for a wide photo in a tall box. The
/// stored id is one of [kPhotoCropChoices]; any blank/unknown value normalises
/// to `null` (중앙) so a stray string never sticks.

/// A selectable crop position for one photo. [id] is what persists; [alignment]
/// is fed to the image's `alignment` when `BoxFit.cover` crops it (null = 중앙,
/// i.e. keep the centre — the default).
class PhotoCropChoice {
  const PhotoCropChoice(this.id, this.label, this.alignment);

  final String id;
  final String label;
  final Alignment alignment;
}

/// The pickable positions. "중앙" is represented by a `null` stored value (not
/// an id), so it is intentionally absent here; the picker offers it separately.
const List<PhotoCropChoice> kPhotoCropChoices = [
  PhotoCropChoice('top', '위', Alignment.topCenter),
  PhotoCropChoice('bottom', '아래', Alignment.bottomCenter),
  PhotoCropChoice('left', '왼쪽', Alignment.centerLeft),
  PhotoCropChoice('right', '오른쪽', Alignment.centerRight),
];

/// Maps a stored crop id to the image alignment for a cover-crop. `null`/blank/
/// 'center'/unknown → `null` = 중앙 (keep the centre, the default behaviour).
Alignment? photoCropAlignmentForChoice(String? choice) {
  if (choice == null || choice.trim().isEmpty) return null;
  for (final c in kPhotoCropChoices) {
    if (c.id == choice) return c.alignment;
  }
  return null;
}

List<String?> decodePhotoCrops(String? json) {
  if (json == null || json.trim().isEmpty) return const [];
  try {
    final list = jsonDecode(json);
    if (list is! List) return const [];
    return [
      for (final v in list)
        v is String && photoCropAlignmentForChoice(v) != null ? v : null,
    ];
  } catch (_) {
    return const [];
  }
}

String? encodePhotoCrops(List<String?> crops) {
  var end = crops.length;
  while (end > 0 && photoCropAlignmentForChoice(crops[end - 1]) == null) {
    end--;
  }
  if (end == 0) return null;
  return jsonEncode([
    for (final c in crops.sublist(0, end))
      photoCropAlignmentForChoice(c) != null ? c : null,
  ]);
}

String? cropAt(List<String?> crops, int index) =>
    index >= 0 && index < crops.length ? crops[index] : null;

List<String?> withCropAt(List<String?> crops, int index, String? id) {
  final normalized = photoCropAlignmentForChoice(id) != null ? id : null;
  final next = List<String?>.of(crops);
  while (next.length <= index) {
    next.add(null);
  }
  next[index] = normalized;
  return next;
}
