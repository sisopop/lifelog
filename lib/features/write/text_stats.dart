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
/// (`>= chars`), or null when below the first one (50). Pure & top-level so
/// it is unit-testable; the write screen just renders the non-null result.
String? writingMilestone(int chars) {
  if (chars >= 2000) return '📚 2000자, 한 편의 글이 됐어요';
  if (chars >= 1000) return '🏆 1000자 돌파, 대단해요!';
  if (chars >= 500) return '🔥 500자를 넘겼어요!';
  if (chars >= 300) return '✨ 300자, 술술 써지네요';
  if (chars >= 100) return '✍️ 벌써 100자를 넘겼어요';
  if (chars >= 50) return '🌱 좋은 시작이에요';
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

/// Whether a title is long enough to risk being clipped where titles show on a
/// single line (entry lists, cards). Trims first, then compares the grapheme
/// length against [max] (default 40, so Korean syllables and emoji each count
/// as one). Empty/whitespace-only is never "too long". Pure & top-level so it
/// is unit-testable; the title field shows a gentle hint when this is true.
bool isTitleTooLong(String title, {int max = 40}) {
  return title.trim().characters.length > max;
}

/// Whether the title merely repeats the body's first non-empty line, so the
/// writer can drop the duplicate. Compares the trimmed title against the first
/// non-empty trimmed line of [content], case-insensitively. False when either
/// is empty. Pairs with [suggestTitleFromContent] (which fills the title from
/// that very line). Pure & top-level so it is unit-testable; the title field
/// shows a gentle hint when true.
bool titleEchoesFirstLine(String title, String content) {
  final t = title.trim();
  if (t.isEmpty) return false;
  for (final line in content.split('\n')) {
    final l = line.trim();
    if (l.isEmpty) continue;
    return l.toLowerCase() == t.toLowerCase();
  }
  return false;
}

/// Hashtag-style tokens (`#word`) typed in the body, offered as one-tap tag
/// suggestions. Returns each tag text without the leading `#`, in first-seen
/// order, case-insensitively de-duplicated, and excluding any already in
/// [existing]. A token must have at least one non-whitespace, non-`#` char
/// after the `#`; trailing sentence punctuation (e.g. `#가족,` `#cafe.`) is
/// stripped, and a token that is only punctuation is ignored. Capped at [max]
/// (default 5). Pure & top-level so it is unit-testable; the write screen
/// renders the result as add-chips.
List<String> extractHashtagSuggestions(String content, List<String> existing,
    {int max = 5}) {
  final seen = <String>{for (final e in existing) e.toLowerCase()};
  final out = <String>[];
  for (final m in RegExp(r'#([^\s#]+)').allMatches(content)) {
    final tag = m
        .group(1)!
        .replaceAll(RegExp(r'[.,!?;:…·。！？、，)\]}]+$'), '');
    if (tag.isEmpty) continue;
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

/// Number of question sentences in the body — runs of `?`/`？` count once each
/// (so `정말??` is one question, matching [countSentences]'s handling of
/// repeated terminators). A gentle nudge that the writer is asking themselves
/// things. Pure & top-level so it is unit-testable; the write meta appends it
/// to the count line only when there is at least one.
int countQuestions(String text) {
  return RegExp(r'[?？]+').allMatches(text).length;
}

/// Average characters per sentence for the body — a rough writing-pace hint.
/// Returns null until there are at least 2 sentences (a single sentence is not
/// informative) or when the body is empty. Uses the grapheme char count over
/// [countSentences], rounded to the nearest whole number. Pure & top-level so
/// it is unit-testable; the write screen shows it only when non-null.
int? averageSentenceLength(String text) {
  final sentences = countSentences(text);
  if (sentences < 2) return null;
  final chars = textStats(text).chars;
  if (chars == 0) return null;
  return (chars / sentences).round();
}

/// The grapheme length of the longest sentence in the body — a complement to
/// the sentence average that surfaces a single sprawling (run-on) sentence.
/// Sentences are split like [countSentences] (on `.!?。！？…` and line breaks),
/// trimmed, and measured by graphemes (so Korean syllables and emoji each count
/// as one). Returns null below 2 sentences (with one sentence it just equals
/// the average) or when empty. Pure & top-level so it is unit-testable; the
/// write meta appends it to the average line only when non-null.
int? longestSentenceLength(String text) {
  final segs = text
      .split(RegExp(r'[.!?。！？…\n]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (segs.length < 2) return null;
  var longest = 0;
  for (final s in segs) {
    final n = s.characters.length;
    if (n > longest) longest = n;
  }
  return longest;
}

/// A gentle nudge to break a long, single-block entry into paragraphs for
/// readability. Returns the hint only when the body is past [minChars]
/// (default 400) yet still has at most one paragraph (no blank line);
/// otherwise null, so short or already-split entries never see it. Pure &
/// top-level so it is unit-testable; the write meta renders the non-null result.
String? paragraphBreakHint(int chars, int paragraphs, {int minChars = 400}) {
  if (chars < minChars || paragraphs > 1) return null;
  return '긴 글은 빈 줄로 문단을 나누면 읽기 좋아요';
}

/// A gentle nudge when a single sentence runs very long (past [max], default
/// 150 graphemes) — breaking it up reads more easily. Takes the already-computed
/// [longest] sentence length (see [longestSentenceLength]); returns null when it
/// is null or within the limit. Pure & top-level so it is unit-testable; the
/// write meta renders the non-null result.
String? longSentenceHint(int? longest, {int max = 150}) {
  if (longest == null || longest <= max) return null;
  return '한 문장이 길어요 · 끊어 쓰면 읽기 편해요';
}

/// Average characters per word for the body — a rough vocabulary-density hint
/// shown next to the sentence average. Whitespace is excluded so spaces don't
/// inflate it (unlike the sentence average's rough char count). Counts
/// graphemes, so Korean syllables and emoji each count as one. Returns null
/// until there are at least 2 words (a single word is not informative) or when
/// there are no letters. Pure & top-level so it is unit-testable; the write
/// meta shows it only when non-null.
int? averageWordLength(String text) {
  final words = textStats(text).words;
  if (words < 2) return null;
  final letters = text.replaceAll(RegExp(r'\s+'), '').characters.length;
  if (letters == 0) return null;
  return (letters / words).round();
}
