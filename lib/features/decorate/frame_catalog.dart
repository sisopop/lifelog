import 'package:flutter/material.dart';

/// A single selectable photo frame style (border color/width/corner radius).
/// Kept intentionally simple (no bg-color/photo cropping changes) so it can
/// wrap an existing [PhotoView] without altering its layout size.
class PhotoFrame {
  const PhotoFrame(this.id, this.label, this.borderColor, this.borderWidth,
      {this.cornerRadius = 16});

  /// Stable id persisted in [DiaryEntry.photoFrames]; never rename existing
  /// ids (would silently "forget" frames already chosen on old entries).
  final String id;
  final String label;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
}

/// Frame catalog, sticker/washi-tape-catalog style (see sticker_catalog.dart,
/// washi_tape_catalog.dart). Ids are stable; visuals may evolve.
const List<PhotoFrame> kPhotoFrames = [
  PhotoFrame('white', '화이트', Colors.white, 8),
  PhotoFrame('black', '블랙', Colors.black87, 8),
  PhotoFrame('gold', '골드', Color(0xFFD4AF37), 6),
  PhotoFrame('film', '필름', Color(0xFF1A1A1A), 12, cornerRadius: 4),
];

/// Looks up a frame by id; null (or an unknown/legacy id) means no frame.
PhotoFrame? photoFrameById(String? id) {
  if (id == null) return null;
  for (final f in kPhotoFrames) {
    if (f.id == id) return f;
  }
  return null;
}
