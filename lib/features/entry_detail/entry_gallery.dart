import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../decorate/framed_photo.dart';
import '../decorate/photo_frames.dart';
import '../decorate/photo_memos.dart';
import '../decorate/photo_stickers.dart';
import '../decorate/photo_tapes.dart';

/// Full-width photo carousel for an entry's attached photos (read-only),
/// Instagram-style: one photo fills the width at a time, swipe sideways to
/// see the rest (never stacked vertically), with dot page indicators when
/// there's more than one photo. Extracted from EntryDetailScreen to keep
/// that file under the size limit.
class EntryGallery extends StatefulWidget {
  const EntryGallery(
    this.mediaUrls, {
    super.key,
    this.photoFrames = const [],
    this.photoStickers = const [],
    this.photoTapes = const [],
    this.photoMemos = const [],
  });

  final List<String> mediaUrls;

  /// Per-photo frame ids, index-aligned with [mediaUrls] (see photo_frames.dart).
  final List<String?> photoFrames;

  /// Per-photo sticker emoji, index-aligned with [mediaUrls] (see photo_stickers.dart).
  final List<String?> photoStickers;

  /// Per-photo washi-tape ids, index-aligned with [mediaUrls] (see photo_tapes.dart).
  final List<String?> photoTapes;

  /// Per-photo memo captions, index-aligned with [mediaUrls] (see photo_memos.dart).
  final List<String?> photoMemos;

  @override
  State<EntryGallery> createState() => _EntryGalleryState();
}

class _EntryGalleryState extends State<EntryGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.mediaUrls;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => FramedPhoto(
                photos[i],
                frameId: frameAt(widget.photoFrames, i),
                stickerEmoji: stickerAt(widget.photoStickers, i),
                tapeId: tapeAt(widget.photoTapes, i),
                memoText: memoAt(widget.photoMemos, i),
                iconSize: 40,
              ),
            ),
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < photos.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        i == _page ? AppColors.primary : AppColors.divider,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
