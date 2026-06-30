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

/// Suggests a title from the body: the first non-empty line, trimmed. When that
/// line is too long to read as a title (> 50 graphemes), falls back to its
/// first sentence (split on sentence-ending punctuation) if that alone fits,
/// so flowing single-paragraph entries still get a suggestion. Returns null
/// when the body has no text, or when even the first sentence is too long.
/// Pure & top-level so it is unit-testable; the write screen offers it as a
/// one-tap chip only while the title is empty.
String? suggestTitleFromContent(String content) {
  for (final line in content.split('\n')) {
    final t = line.trim();
    if (t.isEmpty) continue;
    if (t.characters.length <= 50) return t;
    for (final seg in t.split(RegExp(r'[.!?。！？…]+'))) {
      final s = seg.trim();
      if (s.isEmpty) continue;
      return s.characters.length <= 50 ? s : null;
    }
    return null;
  }
  return null;
}

/// Hashtag-style tokens (`#word`) typed in the body, offered as one-tap tag
/// suggestions. Returns each tag text without the leading `#`, in first-seen
/// order, case-insensitively de-duplicated, and excluding any already in
/// [existing]. A token must have at least one non-whitespace, non-`#` char
/// after the `#`. Capped at [max] (default 5). Pure & top-level so it is
/// unit-testable; the write screen renders the result as add-chips.
List<String> extractHashtagSuggestions(String content, List<String> existing,
    {int max = 5}) {
  final seen = <String>{for (final e in existing) e.toLowerCase()};
  final out = <String>[];
  for (final m in RegExp(r'#([^\s#]+)').allMatches(content)) {
    final tag = m.group(1)!;
    if (!seen.add(tag.toLowerCase())) continue;
    out.add(tag);
    if (out.length >= max) break;
  }
  return out;
}

/// Quick-add tag chips for the write screen: takes the already frequency-ranked
/// [available] tags (from `availableTags`, most-used first) and drops any in
/// [current], capped at [max] (default 6). Pure & top-level so it is
/// unit-testable; the write screen renders the rest as one-tap add-chips.
List<String> frequentTagSuggestions(
    List<String> available, List<String> current,
    {int max = 6}) {
  final exclude = current.toSet();
  final out = <String>[];
  for (final t in available) {
    if (exclude.contains(t)) continue;
    out.add(t);
    if (out.length >= max) break;
  }
  return out;
}

/// Rough sentence count for the body: runs of text separated by
/// sentence-ending punctuation (`. ! ? 。 ！ ？ …`) or line breaks, counting
/// only non-empty trimmed segments. Text with no terminator counts as one
/// sentence; punctuation/whitespace only counts as zero. Pure & top-level so
/// it is unit-testable.
int countSentences(String text) {
  return text
      .split(RegExp(r'[.!?。！？…\n]+'))
      .where((p) => p.trim().isNotEmpty)
      .length;
}

/// Rough paragraph count for the body: blocks of text separated by a blank
/// line (one or more line breaks with only whitespace between), counting only
/// non-empty trimmed blocks. A body with no blank line is a single paragraph;
/// empty/whitespace only counts as zero. Pure & top-level so it is
/// unit-testable; the write screen shows it only once there are 2+ paragraphs.
int countParagraphs(String text) {
  return text
      .split(RegExp(r'\n[ \t]*\n'))
      .where((p) => p.trim().isNotEmpty)
      .length;
}
