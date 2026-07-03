part of 'write_screen.dart';

/// Per-photo decoration state (frames + stickers + tapes + memos), factored out
/// of _WriteScreenState to keep write_screen.dart under the 500-line limit. See
/// photo_frames.dart / photo_stickers.dart / photo_tapes.dart / photo_memos.dart
/// for the underlying index-aligned JSON array encoding.
mixin _PhotoDecoState on ConsumerState<WriteScreen> {
  final List<String?> _photoFrames = [];
  final List<String?> _photoStickers = [];
  final List<String?> _photoTapes = [];
  final List<String?> _photoMemos = [];

  void _prefillPhotoDeco(DiaryEntry entry) {
    _photoFrames
      ..clear()
      ..addAll(decodePhotoFrames(entry.photoFrames));
    _photoStickers
      ..clear()
      ..addAll(decodePhotoStickers(entry.photoStickers));
    _photoTapes
      ..clear()
      ..addAll(decodePhotoTapes(entry.photoTapes));
    _photoMemos
      ..clear()
      ..addAll(decodePhotoMemos(entry.photoMemos));
  }

  void _removePhotoDecoAt(int i) {
    if (i < _photoFrames.length) _photoFrames.removeAt(i);
    if (i < _photoStickers.length) _photoStickers.removeAt(i);
    if (i < _photoTapes.length) _photoTapes.removeAt(i);
    if (i < _photoMemos.length) _photoMemos.removeAt(i);
  }

  void _setFrameAt(int i, String? frameId) {
    final next = withFrameAt(_photoFrames, i, frameId);
    _photoFrames
      ..clear()
      ..addAll(next);
  }

  void _setStickerAt(int i, String? emoji) {
    final next = withStickerAt(_photoStickers, i, emoji);
    _photoStickers
      ..clear()
      ..addAll(next);
  }

  void _setTapeAt(int i, String? tapeId) {
    final next = withTapeAt(_photoTapes, i, tapeId);
    _photoTapes
      ..clear()
      ..addAll(next);
  }

  void _setMemoAt(int i, String? memo) {
    final next = withMemoAt(_photoMemos, i, memo);
    _photoMemos
      ..clear()
      ..addAll(next);
  }
}
