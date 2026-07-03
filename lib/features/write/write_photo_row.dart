part of 'write_screen.dart';

/// Horizontal strip of attached-photo thumbnails: tap a thumbnail to pick a
/// decorative frame for it, tap the ✕ badge to remove it. Owns the picker
/// sheet itself (needs a BuildContext) and reports the result up via
/// [onFramePicked] so WriteScreen only has to call setState. Extracted from
/// WriteScreen's build() to keep that file under the size limit (see
/// write_widgets.dart / write_deco_tile.dart for the same pattern).
class _PhotoThumbnailsRow extends StatelessWidget {
  const _PhotoThumbnailsRow({
    required this.photoPaths,
    required this.photoFrames,
    required this.onRemove,
    required this.onFramePicked,
  });

  final List<String> photoPaths;
  final List<String?> photoFrames;
  final void Function(int index) onRemove;

  /// Called with the newly chosen frame id (or null to clear).
  final void Function(int index, String? frameId) onFramePicked;

  Future<void> _pickFrame(BuildContext context, int index) async {
    final picked =
        await showFramePickerSheet(context, current: frameAt(photoFrames, index));
    if (picked == null) return; // dismissed without a choice
    onFramePicked(index, picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoPaths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Stack(
          children: [
            GestureDetector(
              onTap: () => _pickFrame(context, i),
              child: FramedPhoto(
                photoPaths[i],
                frameId: frameAt(photoFrames, i),
                width: 84,
                height: 84,
                borderRadius: 12,
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
