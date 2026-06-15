import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';

/// Local placeholder for AI summarization. Produces a short, friendly
/// one-liner from the entry. Replaced by the `/ai/summarize` API later.
String mockSummarize(DiaryEntry entry) {
  final moodPart = switch (entry.mood) {
    Mood.good => '기분 좋았던',
    Mood.neutral => '평범했던',
    Mood.hard => '조금 힘들었던',
    null => '',
  };

  // First sentence (or first ~40 chars) of the content.
  final normalized = entry.content.replaceAll('\n', ' ').trim();
  final sentenceEnd = normalized.indexOf(RegExp(r'[.!?。]'));
  var gist = sentenceEnd > 0 && sentenceEnd < 50
      ? normalized.substring(0, sentenceEnd)
      : normalized;
  if (gist.length > 40) gist = '${gist.substring(0, 40)}…';

  final tagPart = entry.tags.isNotEmpty ? ' (${entry.tags.take(2).join(', ')})' : '';
  final prefix = moodPart.isNotEmpty ? '$moodPart 하루. ' : '';
  return '$prefix$gist$tagPart';
}
