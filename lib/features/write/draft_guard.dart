import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Whether closing the writer would discard unsaved input worth a confirmation
/// prompt. Only *new* entries are guarded — an in-progress draft that was never
/// saved is easy to lose by tapping the close button. Editing an existing entry
/// leaves the saved copy intact, so backing out of an edit is not guarded.
///
/// Pure & top-level so the rule is unit-testable; the write screen just calls
/// it before popping.
bool hasUnsavedDraft({
  required bool isEditing,
  required String title,
  required String content,
}) {
  if (isEditing) return false;
  return title.trim().isNotEmpty || content.trim().isNotEmpty;
}

/// Asks the user whether to abandon an unsaved draft. Returns true to leave.
Future<bool> confirmLeaveDraft(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('작성을 그만둘까요?'),
      content: const Text('저장하지 않은 내용은 사라져요.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('계속 작성')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('나가기',
                style: TextStyle(color: AppColors.moodHard))),
      ],
    ),
  );
  return leave == true;
}
