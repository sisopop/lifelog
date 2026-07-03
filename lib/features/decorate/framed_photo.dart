import 'package:flutter/material.dart';

import '../../shared/widgets/photo.dart';
import 'frame_catalog.dart';

/// A [PhotoView] optionally wrapped in a decorative [PhotoFrame] border and/or
/// topped with a corner sticker emoji. Both the border and the sticker are
/// purely additive (border paints on the widget's own edge, sticker is a
/// [Positioned] overlay that doesn't affect Stack sizing), so adding/removing
/// either never changes layout size — safe to drop into existing fixed-size
/// thumbnails or an unconstrained carousel page alike.
class FramedPhoto extends StatelessWidget {
  const FramedPhoto(
    this.path, {
    super.key,
    this.frameId,
    this.stickerEmoji,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.iconSize = 20,
  });

  final String path;
  final String? frameId;
  final String? stickerEmoji;
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
    final framed = frame == null
        ? photo
        : Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: frame.borderColor, width: frame.borderWidth),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: photo,
          );
    final sticker = stickerEmoji;
    if (sticker == null || sticker.isEmpty) return framed;
    return Stack(
      clipBehavior: Clip.none,
      // Pass our incoming constraints straight through to [framed] (unchanged),
      // so the photo fills its box identically whether or not a sticker is
      // present — the default StackFit.loose would let a small image shrink,
      // changing how the photo sits in a tight parent (e.g. the 1:1 carousel).
      fit: StackFit.passthrough,
      children: [
        framed,
        Positioned(
          right: 2,
          bottom: 2,
          child: Text(sticker, style: const TextStyle(fontSize: 20)),
        ),
      ],
    );
  }
}
