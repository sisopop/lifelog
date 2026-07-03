import 'package:flutter/material.dart';

import '../../shared/widgets/photo.dart';
import 'frame_catalog.dart';

/// A [PhotoView] optionally wrapped in a decorative [PhotoFrame] border.
/// The border paints along the widget's own edge (no extra padding), so
/// adding/removing a frame never changes layout size — safe to drop into
/// existing fixed-size thumbnails or an unconstrained carousel page alike.
class FramedPhoto extends StatelessWidget {
  const FramedPhoto(
    this.path, {
    super.key,
    this.frameId,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.iconSize = 20,
  });

  final String path;
  final String? frameId;
  final double? width;
  final double? height;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final frame = photoFrameById(frameId);
    final radius = frame?.cornerRadius ?? borderRadius;
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: PhotoView(path, width: width, height: height, iconSize: iconSize),
    );
    if (frame == null) return photo;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: frame.borderColor, width: frame.borderWidth),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: photo,
    );
  }
}
