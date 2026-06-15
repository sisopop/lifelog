import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/entry_card.dart';
import '../entries/entries_provider.dart';
import '../stats/stats_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2026년 6월 14일 (일)',
                          style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                      SizedBox(height: 4),
                      Text('오늘 어떤 하루였나요?',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: IconButton(
                    icon: const Icon(Icons.person, color: AppColors.primary),
                    onPressed: () => context.push('/settings'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AiPromptCard(onWrite: () => context.push('/write')),
            const SizedBox(height: 16),
            const _WeeklyProgress(),
            const SizedBox(height: 24),
            const Text('최근 기록',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EntryCard(e, onTap: () => context.push('/entry/${e.entryId}')),
                )),
          ],
        ),
      ),
    );
  }
}

class _AiPromptCard extends StatelessWidget {
  const _AiPromptCard({required this.onWrite});
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('AI 질문',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('오늘 가장 기억하고 싶은 순간은?',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
              ),
              onPressed: onWrite,
              child: const Text('바로 쓰기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgress extends ConsumerWidget {
  const _WeeklyProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weeklyProgressProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이번 주 기록률',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: week.map((d) {
                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: d.done ? AppColors.primary : AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: d.done
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(d.label,
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
