import 'package:flutter/material.dart';

import 'text_color_catalog.dart';

/// "글자 넣기" 다이얼로그가 돌려주는 입력값(문구·잉크 색·굵기).
class TextLayerInput {
  const TextLayerInput(this.text, this.colorValue, this.bold);

  /// 앞뒤 공백을 다듬은 글 내용(빈 문구면 다이얼로그가 null을 돌려주므로 항상 비지 않음).
  final String text;

  /// 고른 잉크 색(ARGB 정수).
  final int colorValue;

  /// 굵게 그릴지.
  final bool bold;
}

/// 문구·잉크 색·굵기를 고르는 "글자 넣기" 다이얼로그를 띄운다. 취소하거나 문구가
/// 비어 있으면 null을 돌려준다. 색 스와치와 굵게 스위치는 입력칸 미리보기에 곧바로
/// 반영된다. (page_deco_playground가 500줄 상한을 넘지 않도록 분리해 둔 파일.)
Future<TextLayerInput?> showTextLayerDialog(BuildContext context) async {
  final controller = TextEditingController();
  var color = kTextInkColors.first;
  var bold = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('글자 넣기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 40,
              style: TextStyle(
                color: color,
                fontWeight: bold ? FontWeight.w700 : null,
              ),
              decoration: const InputDecoration(hintText: '예: 오늘의 한마디'),
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
            Wrap(
              spacing: 10,
              children: [
                for (final c in kTextInkColors)
                  GestureDetector(
                    onTap: () => setDialog(() => color = c),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: c,
                      child: color == c
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.format_bold, size: 20),
                const SizedBox(width: 8),
                const Text('굵게'),
                const Spacer(),
                Switch(
                  value: bold,
                  onChanged: (v) => setDialog(() => bold = v),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('추가'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  final text = controller.text.trim();
  if (text.isEmpty) return null;
  return TextLayerInput(text, color.toARGB32(), bold);
}
