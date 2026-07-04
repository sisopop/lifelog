import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/photo.dart';
import '../decorate/framed_photo.dart';
import '../decorate/photo_frames.dart';
import '../decorate/photo_memos.dart';
import '../decorate/photo_stickers.dart';
import '../decorate/photo_tapes.dart';
import 'gallery_aspect.dart';

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

  /// Intrinsic pixel size of the first photo, once decoded — drives the
  /// carousel's aspect ratio so photos show near their natural shape instead of
  /// a forced 1:1 crop. Null until resolved (then the box is a 1:1 fallback).
  int? _w;
  int? _h;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolveSize();
  }

  @override
  void didUpdateWidget(EntryGallery old) {
    super.didUpdateWidget(old);
    // Re-measure only when the leading photo actually changes.
    final oldFirst = old.mediaUrls.isEmpty ? null : old.mediaUrls.first;
    final newFirst = widget.mediaUrls.isEmpty ? null : widget.mediaUrls.first;
    if (oldFirst != newFirst) {
      _w = null;
      _h = null;
      _resolveSize();
    }
  }

  /// Decodes the first photo to learn its width/height, then updates the box
  /// ratio. Uses [photoProvider] so it works for base64/network/file alike.
  void _resolveSize() {
    if (widget.mediaUrls.isEmpty) return;
    _detach();
    final stream =
        photoProvider(widget.mediaUrls.first).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          setState(() {
            _w = info.image.width;
            _h = info.image.height;
          });
        }
        _detach();
      },
      onError: (_, _) => _detach(),
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.mediaUrls;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: galleryAspectRatio(_w, _h),
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
