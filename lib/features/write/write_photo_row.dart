part of 'write_screen.dart';

/// Horizontal strip of attached-photo thumbnails: tap a thumbnail to open a
/// "사진 꾸미기" menu (프레임 / 스티커 / 테이프), tap the ✕ badge to remove it.
/// Owns the menu + picker sheets itself (needs a BuildContext) and reports
/// results up via [onFramePicked]/[onStickerPicked]/[onTapePicked] so
/// WriteScreen only has to call setState. Extracted from WriteScreen's build()
/// to keep that file under the size limit (see write_widgets.dart /
/// write_deco_tile.dart for the same pattern).
class _PhotoThumbnailsRow extends StatelessWidget {
  const _PhotoThumbnailsRow({
    required this.photoPaths,
    required this.photoFrames,
    required this.photoStickers,
    required this.photoTapes,
    required this.onRemove,
    required this.onFramePicked,
    required this.onStickerPicked,
    required this.onTapePicked,
  });

  final List<String> photoPaths;
  final List<String?> photoFrames;
  final List<String?> photoStickers;
  final List<String?> photoTapes;
  final void Function(int index) onRemove;

  /// Called with the newly chosen frame id (or null to clear).
  final void Function(int index, String? frameId) onFramePicked;

  /// Called with the newly chosen sticker emoji (or null to clear).
  final void Function(int index, String? emoji) onStickerPicked;

  /// Called with the newly chosen tape id (or null to clear).
  final void Function(int index, String? tapeId) onTapePicked;

  /// Tap = a small menu of what to decorate; tap and long-press are no longer
  /// enough gestures once we have three decoration kinds, so route them all
  /// through one sheet.
  Future<void> _pickDeco(BuildContext context, int index) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop_square_rounded),
              title: const Text('프레임'),
              onTap: () => Navigator.pop(context, 'frame'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('스티커'),
              onTap: () => Navigator.pop(context, 'sticker'),
            ),
            ListTile(
              leading: const Icon(Icons.horizontal_rule_rounded),
              title: const Text('테이프'),
              onTap: () => Navigator.pop(context, 'tape'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'frame':
        await _pickFrame(context, index);
      case 'sticker':
        await _pickSticker(context, index);
      case 'tape':
        await _pickTape(context, index);
    }
  }

  Future<void> _pickFrame(BuildContext context, int index) async {
    final picked =
        await showFramePickerSheet(context, current: frameAt(photoFrames, index));
    if (picked == null) return; // dismissed without a choice
    onFramePicked(index, picked.isEmpty ? null : picked);
  }

  Future<void> _pickSticker(BuildContext context, int index) async {
    final picked = await showStickerPickerSheet(context,
        current: stickerAt(photoStickers, index));
    if (picked == null) return; // dismissed without a choice
    onStickerPicked(index, picked.isEmpty ? null : picked);
  }

  Future<void> _pickTape(BuildContext context, int index) async {
    final picked =
        await showTapePickerSheet(context, current: tapeAt(photoTapes, index));
    if (picked == null) return; // dismissed without a choice
    onTapePicked(index, picked.isEmpty ? null : picked);
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
              onTap: () => _pickDeco(context, i),
              child: FramedPhoto(
                photoPaths[i],
                frameId: frameAt(photoFrames, i),
                stickerEmoji: stickerAt(photoStickers, i),
                tapeId: tapeAt(photoTapes, i),
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
