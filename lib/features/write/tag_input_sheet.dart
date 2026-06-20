import 'package:flutter/material.dart';

import '../tags/tag_suggest.dart';

/// Bottom sheet to add a tag, with live suggestions drawn from existing tags.
/// Returns the chosen/typed tag (trimmed), or null if cancelled.
Future<String?> showTagInputSheet({
  required BuildContext context,
  required List<String> allTags,
  required List<String> exclude,
}) {
  final ctrl = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
      ),
      child: StatefulBuilder(
        builder: (ctx, setSheet) {
          final suggestions = suggestTags(allTags, ctrl.text, exclude);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('태그 추가',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: '예: 여행, 가족'),
                onChanged: (_) => setSheet(() {}),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: suggestions
                      .map((t) => ActionChip(
                            label: Text('#$t'),
                            onPressed: () => Navigator.pop(ctx, t),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('추가'),
              ),
            ],
          );
        },
      ),
    ),
  );
}
