import '../../shared/models/diary_entry.dart';

/// Pure: builds the plain-text representation of an [entry] for copying to the
/// clipboard. Title (when present) on the first line, then the body, then the
/// location as `📍 place`, then the tags as `#tag` joined by spaces. Blank
/// pieces are skipped so the result has no dangling separators.
String entryClipboardText(DiaryEntry entry) {
  final parts = <String>[];

  final title = (entry.title ?? '').trim();
  if (title.isNotEmpty) parts.add(title);

  final body = entry.content.trim();
  if (body.isNotEmpty) parts.add(body);

  final place = (entry.location ?? '').trim();
  if (place.isNotEmpty) parts.add('📍 $place');

  final tags = entry.tags
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .map((t) => '#$t')
      .join(' ');
  if (tags.isNotEmpty) parts.add(tags);

  return parts.join('\n\n');
}
