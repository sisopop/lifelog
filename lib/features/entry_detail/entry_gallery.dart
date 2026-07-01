import 'package:flutter/material.dart';

import '../../shared/widgets/photo.dart';

/// Horizontal strip of an entry's attached photos (read-only). Extracted from
/// EntryDetailScreen to keep that file under the size limit.
class EntryGallery extends StatelessWidget {
  const EntryGallery(this.mediaUrls, {super.key});

  final List<String> mediaUrls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mediaUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: PhotoView(mediaUrls[i], width: 260, height: 200, iconSize: 40),
        ),
      ),
    );
  }
}
