import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Dialog to write, edit, or clear a short memo (caption) for one photo.
///
/// Returns:
/// - the trimmed caption text when the user saves a non-empty note,
/// - `''` (empty string) when the user saves an empty field (clear),
/// - `null` when the dialog is dismissed / cancelled without saving.
Future<String?> showMemoDialog(BuildContext context, {String? current}) {
  final controller = TextEditingController(text: current ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('사진 메모'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        maxLength: 120,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: '이 사진에 대한 메모…',
        ),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // null = cancel
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('저장'),
        ),
      ],
    ),
  );
}
