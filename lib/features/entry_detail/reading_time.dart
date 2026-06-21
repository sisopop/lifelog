import 'package:characters/characters.dart';

/// Average reading pace for Korean diary prose, in characters per minute.
const _charsPerMinute = 400;

/// Below this length an entry reads in a glance, so we skip the time estimate
/// (it would always round up to "약 1분" and just add noise).
const _minCharsForEstimate = 280;

/// Pure: grapheme-aware character count of [text] after trimming.
int readingCharCount(String text) => text.trim().characters.length;

/// Pure: estimated minutes to read [charCount] characters. Returns 0 for short
/// entries (below [_minCharsForEstimate]) so callers can omit the estimate.
int readingMinutes(int charCount) {
  if (charCount < _minCharsForEstimate) return 0;
  return (charCount / _charsPerMinute).ceil();
}

/// Pure: the meta line shown under an entry body, e.g. "152자" or
/// "640자 · 약 2분 읽기". Empty text yields an empty string.
String readingMetaLabel(String text) {
  final chars = readingCharCount(text);
  if (chars == 0) return '';
  final minutes = readingMinutes(chars);
  return minutes == 0 ? '$chars자' : '$chars자 · 약 $minutes분 읽기';
}
