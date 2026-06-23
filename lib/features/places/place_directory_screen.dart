import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../entries/entries_provider.dart';
import '../home/journal_activity.dart';
import 'place_directory.dart';

/// Lists every location used across records with its count, newest-used first.
/// Tapping a row opens that place's records. Reached from settings.
class PlaceDirectoryScreen extends ConsumerWidget {
  const PlaceDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final places = placeCountsSorted(entries);
    final lastVisits = lastVisitByPlace(entries);
    final moods = dominantMoodByPlace(entries);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('장소 모아보기', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: places.isEmpty
          ? const Center(
              child: Text('아직 장소가 기록된 글이 없어요',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: places.length + 1,
              separatorBuilder: (_, i) =>
                  i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('장소 ${places.length}곳',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  );
                }
                final p = places[i - 1];
                final last = lastVisits[p.key];
                final mood = moods[p.key];
                final subtitle = last == null
                    ? '${p.value}개 기록'
                    : '${p.value}개 기록 · 마지막 ${relativeDayLabel(last, now)}';
                final title = mood == null ? p.key : '${mood.emoji} ${p.key}';
                return ListTile(
                  leading: const Icon(Icons.place_outlined,
                      color: AppColors.primaryDark),
                  title: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(subtitle),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textHint),
                  onTap: () => context.push(
                    Uri(path: '/place', queryParameters: {'l': p.key})
                        .toString(),
                  ),
                );
              },
            ),
    );
  }
}
