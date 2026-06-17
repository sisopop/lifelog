import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'people_provider.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider);
    return Scaffold(
      appBar: AppBar(
          title: const Text('사람', style: TextStyle(fontWeight: FontWeight.w800))),
      body: people.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: people.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final p = people[i];
                final parts = <String>[
                  if (p.journalCount > 0) '함께한 일기장 ${p.journalCount}개',
                  if (p.entryCount > 0) '기록 ${p.entryCount}개',
                ];
                final sub = parts.isEmpty ? '아직 함께한 기록이 없어요' : parts.join(' · ');
                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Text(p.name.characters.first,
                          style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700)),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(sub,
                        style: const TextStyle(color: AppColors.textHint)),
                  ),
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
          SizedBox(height: 12),
          Text('커플·교환 일기장에서 함께하면\n이곳에 사람이 모여요',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
