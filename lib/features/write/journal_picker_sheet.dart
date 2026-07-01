import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/journal.dart';

/// Bottom sheet that lets the writer choose which journal a new entry is saved
/// into. Returns the picked journalId, or null when dismissed. Archived
/// journals are hidden; the current target shows a check. Extracted from
/// WriteScreen to keep that file under the size limit.
Future<String?> showJournalPicker({
  required BuildContext context,
  required List<Journal> journals,
  required String currentId,
}) {
  final active = journals.where((j) => !j.isArchived).toList();
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('어느 일기장에 쓸까요?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          for (final j in active)
            ListTile(
              leading: Text(j.displayIcon, style: const TextStyle(fontSize: 20)),
              title: Text(j.title),
              subtitle: Text(j.type.label),
              trailing: j.journalId == currentId
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, j.journalId),
            ),
        ],
      ),
    ),
  );
}
