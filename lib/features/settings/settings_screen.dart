import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../auth/session.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              title: Text(session.name ?? '나',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('프로필'),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTile(icon: Icons.notifications_none, label: '알림 설정'),
          const _SectionTile(icon: Icons.lock_outline, label: '개인정보 / 보안'),
          const _SectionTile(icon: Icons.help_outline, label: '문의하기'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.moodHard),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.logout, color: AppColors.moodHard),
            label: const Text('로그아웃', style: TextStyle(color: AppColors.moodHard)),
            onPressed: () async {
              await ref.read(sessionProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () {},
      ),
    );
  }
}
