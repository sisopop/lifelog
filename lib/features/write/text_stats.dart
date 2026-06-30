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

/// Character-count milestones surfaced live while writing, as gentle
/// encouragement. Returns the label for the highest threshold reached
/// (`>= chars`), or null when below the first one (100). Pure & top-level so
/// it is unit-testable; the write screen just renders the non-null result.
String? writingMilestone(int chars) {
  if (chars >= 1000) return '🏆 1000자 돌파, 대단해요!';
  if (chars >= 500) return '🔥 500자를 넘겼어요!';
  if (chars >= 300) return '✨ 300자, 술술 써지네요';
  if (chars >= 100) return '✍️ 벌써 100자를 넘겼어요';
  return null;
}

/// Rough reading-time estimate for the entry body, surfaced only once it is
/// long enough to be worth showing (>= 200 graphemes). Korean prose reads at
/// roughly 500 chars/min; returns the minute count rounded up (min 1), or null
/// when the text is still short. Pure & top-level so it is unit-testable.
int? readingMinutes(int chars) {
  if (chars < 200) return null;
  return (chars / 500).ceil();
}

/// Suggests a title from the body: the first non-empty line, trimmed. Returns
/// null when the body has no text, or when that first line is too long to read
/// as a title (> 50 graphemes). Pure & top-level so it is unit-testable; the
/// write screen offers it as a one-tap chip only while the title is empty.
String? suggestTitleFromContent(String content) {
  for (final line in content.split('\n')) {
    final t = line.trim();
    if (t.isEmpty) continue;
    return t.characters.length > 50 ? null : t;
  }
  return null;
}
