import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gentle writing prompts shown on the write screen when the body is empty,
/// to help start a diary entry.
const writingPrompts = <String>[
  '오늘 가장 기억에 남는 순간은 무엇이었나요?',
  '오늘 누군가에게 고마웠던 일이 있나요?',
  '지금 가장 떠오르는 감정은 무엇인가요?',
  '오늘 나를 웃게 한 것은 무엇이었나요?',
  '내일의 나에게 한마디 남긴다면?',
  '오늘 새롭게 알게 된 것이 있나요?',
  '요즘 가장 마음 쓰이는 일은 무엇인가요?',
  '오늘 하루를 한 문장으로 표현한다면?',
  '최근에 나에게 힘이 되어준 것은 무엇인가요?',
  '오늘 하지 못해 아쉬운 일이 있나요?',
];

/// Day-of-year index (0-based) so the default prompt rotates daily.
int promptIndexForDay(DateTime day, int length) {
  if (length <= 0) return 0;
  final dayOfYear = DateTime(day.year, day.month, day.day)
      .difference(DateTime(day.year, 1, 1))
      .inDays;
  return dayOfYear % length;
}

/// Next index, wrapping around the list.
int nextPromptIndex(int current, int length) {
  if (length <= 0) return 0;
  return (current + 1) % length;
}

/// The prompt for [day] from [prompts]. Empty when there are no prompts.
String promptForDay(List<String> prompts, DateTime day) {
  if (prompts.isEmpty) return '';
  return prompts[promptIndexForDay(day, prompts.length)];
}

/// Index of the currently shown writing prompt. Starts on today's prompt
/// and cycles through the list when refreshed.
class WritingPromptNotifier extends Notifier<int> {
  @override
  int build() => promptIndexForDay(DateTime.now(), writingPrompts.length);

  void next() => state = nextPromptIndex(state, writingPrompts.length);
}

final writingPromptIndexProvider =
    NotifierProvider<WritingPromptNotifier, int>(WritingPromptNotifier.new);

/// The current writing prompt text.
final writingPromptProvider = Provider<String>((ref) {
  final i = ref.watch(writingPromptIndexProvider);
  if (writingPrompts.isEmpty) return '';
  return writingPrompts[i % writingPrompts.length];
});
