import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/diary_entry.dart';
import '../entries/entries_provider.dart';

/// Pure: whether there is at least one top-level record on [day]
/// (the time component of [day] is ignored). Replies don't count.
bool hasEntryOn(List<DiaryEntry> entries, DateTime day) {
  return entries.any((e) =>
      e.replyToEntryId == null &&
      e.createdAt.year == day.year &&
      e.createdAt.month == day.month &&
      e.createdAt.day == day.day);
}

/// True when the user has already written a top-level record today.
final wroteTodayProvider = Provider<bool>((ref) {
  final entries = ref.watch(entriesProvider).asData?.value ?? const [];
  return hasEntryOn(entries, DateTime.now());
});
