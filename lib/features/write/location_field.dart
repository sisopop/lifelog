import 'package:flutter/material.dart';

import '../timeline/timeline_filter.dart';

/// Dialog to set/clear the entry's place name, with one-tap chips for places
/// used before (see [recentLocationSuggestions]). Returns the typed/chosen text,
/// `''` to clear, or null when dismissed (no change). Kept out of write_screen
/// to hold its line budget.
Future<String?> showLocationDialog({
  required BuildContext context,
  required List<String> allLocations,
  required String? current,
}) {
  final ctrl = TextEditingController(text: current ?? '');
  final suggestions = recentLocationSuggestions(allLocations, current);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('위치'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: '예: 제주 바닷가, 동네 카페'),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final loc in suggestions)
                  ActionChip(
                    avatar: const Icon(Icons.place, size: 16),
                    label: Text(loc),
                    onPressed: () => Navigator.pop(ctx, loc),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('지우기')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('확인')),
      ],
    ),
  );
}
