import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/photo.dart';

/// Full-width photo carousel for an entry's attached photos (read-only),
/// Instagram-style: one photo fills the width at a time, swipe sideways to
/// see the rest (never stacked vertically), with dot page indicators when
/// there's more than one photo. Extracted from EntryDetailScreen to keep
/// that file under the size limit.
class EntryGallery extends StatefulWidget {
  const EntryGallery(this.mediaUrls, {super.key});

  final List<String> mediaUrls;

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
              itemBuilder: (_, i) => PhotoView(photos[i], iconSize: 40),
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
