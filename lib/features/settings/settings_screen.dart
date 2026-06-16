import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../auth/session.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
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
              subtitle: Text(l.settingsProfile),
            ),
          ),
          const SizedBox(height: 16),
          _LanguageTile(),
          _SectionTile(icon: Icons.notifications_none, label: l.settingsNotifications),
          _SectionTile(icon: Icons.help_outline, label: l.settingsTerms),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.moodHard),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.logout, color: AppColors.moodHard),
            label: Text(l.settingsLogout, style: const TextStyle(color: AppColors.moodHard)),
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

/// App-language picker. `null` = follow device language.
class _LanguageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final current = ref.watch(localeProvider);

    String labelFor(Locale? loc) {
      switch (loc?.languageCode) {
        case 'ko':
          return l.languageKorean;
        case 'en':
          return l.languageEnglish;
        case 'ja':
          return l.languageJapanese;
        default:
          return l.languageSystem;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.language, color: AppColors.textSecondary),
        title: Text(l.settingsLanguage),
        subtitle: Text(labelFor(current)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () async {
          const systemCode = '__system__';
          final options = <Locale?>[null, ...supportedAppLocales];
          // Pop a String code (never null) so we can tell "dismissed" apart
          // from the "follow system" choice.
          final picked = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final loc in options)
                    ListTile(
                      title: Text(labelFor(loc)),
                      trailing: (current?.languageCode ?? systemCode) ==
                              (loc?.languageCode ?? systemCode)
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () =>
                          Navigator.pop(ctx, loc?.languageCode ?? systemCode),
                    ),
                ],
              ),
            ),
          );
          if (picked == null) return; // dismissed without choosing
          final next = picked == systemCode ? null : Locale(picked);
          await ref.read(localeProvider.notifier).setLocale(next);
        },
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
