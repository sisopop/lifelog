import 'package:characters/characters.dart';

/// Character / word counts for the diary content field.
class TextStats {
  const TextStats(this.chars, this.words);
  final int chars;
  final int words;
}

/// Grapheme-aware character count (so Korean syllables and emoji count as one)
/// plus a whitespace-split word count. Leading/trailing whitespace is ignored.
TextStats textStats(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const TextStats(0, 0);
  final chars = trimmed.characters.length;
  final words =
      trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  return TextStats(chars, words);
}
