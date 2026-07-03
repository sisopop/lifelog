import 'package:flutter/material.dart';

import '../../shared/widgets/photo.dart';
import 'frame_catalog.dart';
import 'washi_tape_catalog.dart';

/// A [PhotoView] optionally wrapped in a decorative [PhotoFrame] border and
/// topped with a corner sticker emoji, a washi-tape band, and/or a memo caption
/// bar. The border, sticker, tape, and memo are all purely additive (border
/// paints on the widget's own edge; sticker, tape, and memo are [Positioned]
/// overlays that don't affect Stack sizing), so adding/removing any of them
/// never changes layout size — safe to drop into existing fixed-size thumbnails
/// or an unconstrained carousel page alike.
class FramedPhoto extends StatelessWidget {
  const FramedPhoto(
    this.path, {
    super.key,
    this.frameId,
    this.stickerEmoji,
    this.tapeId,
    this.memoText,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.iconSize = 20,
  });

  final String path;
  final String? frameId;
  final String? stickerEmoji;
  final String? tapeId;
  final String? memoText;
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

    final overlays = <Widget>[];
    final tape = tapeId;
    if (tape != null && tape.isNotEmpty) {
      // A slightly-tilted translucent band across the top-left corner, like a
      // strip of masking tape holding the photo down. Diagonal so it reads as
      // tape rather than a full-width bar, and offset off-edge so its ends are
      // clipped away by [Clip.none]'s parent.
      overlays.add(Positioned(
        top: 6,
        left: -14,
        child: Transform.rotate(
          angle: -0.35,
          child: Container(
            width: 64,
            height: 18,
            color: washiTapeColor(tape),
          ),
        ),
      ));
    }
    final sticker = stickerEmoji;
    if (sticker != null && sticker.isNotEmpty) {
      overlays.add(Positioned(
        right: 2,
        bottom: 2,
        child: Text(sticker, style: const TextStyle(fontSize: 20)),
      ));
    }
    final memo = memoText;
    if (memo != null && memo.trim().isNotEmpty) {
      // A caption bar pinned to the bottom edge of the photo, like an
      // Instagram caption. Positioned (left/right/bottom all set), so it spans
      // the photo's width without affecting the Stack's size.
      overlays.add(Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            color: Colors.black.withValues(alpha: 0.45),
            child: Text(
              memo.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ),
      ));
    }
    if (overlays.isEmpty) return framed;
    return Stack(
      clipBehavior: Clip.none,
      // Pass our incoming constraints straight through to [framed] (unchanged),
      // so the photo fills its box identically whether or not an overlay is
      // present — the default StackFit.loose would let a small image shrink,
      // changing how the photo sits in a tight parent (e.g. the 1:1 carousel).
      fit: StackFit.passthrough,
      children: [framed, ...overlays],
    );
  }
}
