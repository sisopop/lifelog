import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 일기 본문에 자주 쓰는 이모지 모음(픽커 그리드에 그대로 뿌린다). 표정·마음·
/// 날씨·먹거리·활동 순으로 대충 묶어 두었다. 순서가 곧 화면 순서.
const List<String> kDiaryEmojis = [
  '😊', '😍', '🥰', '😌', '🙂', '😎', '🤔', '😅',
  '😂', '😴', '😔', '😢', '😭', '😳', '😡', '🥳',
  '❤️', '💛', '💚', '💙', '💜', '🤍', '💔', '✨',
  '⭐', '🔥', '💯', '👍', '👏', '🙏', '💪', '🎉',
  '☀️', '🌧️', '⛅', '❄️', '🌈', '🌸', '🌿', '🍀',
  '☕', '🍰', '🍜', '🍎', '🍺', '🎂', '📚', '✈️',
];

/// [selection] 위치에 [insert]를 끼운 새 (텍스트, 커서오프셋)를 돌려주는 순수함수.
/// 선택 영역이 있으면 그 범위를 [insert]로 대체하고, 커서가 없거나(-1) 텍스트 길이를
/// 벗어난 잘못된 위치면 안전하게 글 맨 끝에 덧붙인다. 커서는 삽입한 글자 바로 뒤로
/// 옮긴다(오프셋은 TextField와 같은 UTF-16 기준이라 이모지는 2 이상 증가할 수 있다).
(String, int) insertIntoText(
    String text, TextSelection selection, String insert) {
  final start = selection.start;
  final end = selection.end;
  if (start < 0 || end < 0 || start > text.length || end > text.length) {
    return ('$text$insert', text.length + insert.length);
  }
  final next = text.replaceRange(start, end, insert);
  return (next, start + insert.length);
}

/// 이모지 픽커 바텀시트를 열고, 고른 이모지를 [controller]의 현재 커서 위치에
/// 끼워 넣는다(순수 [insertIntoText] 사용). 아무것도 고르지 않으면 그대로 둔다.
Future<void> pickAndInsertEmoji(
    BuildContext context, TextEditingController controller) async {
  final emoji = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _EmojiPickerSheet(),
  );
  if (emoji == null) return;
  final r = insertIntoText(controller.text, controller.selection, emoji);
  controller.value = TextEditingValue(
    text: r.$1,
    selection: TextSelection.collapsed(offset: r.$2),
  );
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('이모지',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final e in kDiaryEmojis)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.of(context).pop(e),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child:
                                Text(e, style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
