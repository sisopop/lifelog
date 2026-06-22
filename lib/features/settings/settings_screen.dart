import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../auth/session.dart';
import '../entries/entries_provider.dart';
import '../export/export_markdown.dart';
import '../journals/default_journal_provider.dart';
import '../journals/journals_provider.dart';
import '../home/home_journal_layout.dart';
import '../places/place_directory.dart';
import '../stats/lifetime_stats.dart';
import 'reading_text_scale.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final l = L10n.of(context);
    final allEntries = ref.watch(entriesProvider).asData?.value ?? const [];
    final stats = computeLifetimeStats(allEntries);
    final placeCount = placeCountsSorted(allEntries).length;
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
          _DefaultJournalTile(),
          _SectionTile(
            icon: Icons.insights,
            label: '내 기록 요약',
            subtitle: stats.isEmpty
                ? null
                : '총 ${stats.totalEntries}개 · ${stats.totalChars}자',
            onTap: () => context.push('/stats'),
          ),
          _SectionTile(
            icon: Icons.tag,
            label: '태그 관리',
            onTap: () => context.push('/tags/manage'),
          ),
          _SectionTile(
            icon: Icons.place_outlined,
            label: '장소 모아보기',
            subtitle: placeCount == 0 ? null : '$placeCount곳',
            onTap: () => context.push('/places'),
          ),
          _LanguageTile(),
          _HomeLayoutTile(),
          _ReadingTextSizeTile(),
          _ExportTile(),
          _SectionTile(
            icon: Icons.notifications_none,
            label: l.settingsNotifications,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('알림 기능은 준비 중이에요')),
            ),
          ),
          _SectionTile(
            icon: Icons.help_outline,
            label: l.settingsTerms,
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'lifelog',
              applicationVersion: '1.0.0',
              applicationLegalese: '프라이버시 우선 · 선택적 공유 일기장\n'
                  '모든 기록은 기기에 저장됩니다.',
            ),
          ),
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

/// Picks the journal the bottom (+) quick-write button targets.
class _DefaultJournalTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journals = (ref.watch(journalsProvider).asData?.value ?? const [])
        .where((j) => !j.isArchived)
        .toList();
    final defaultId = ref.watch(defaultJournalProvider);
    final current = journals.where((j) => j.journalId == defaultId).firstOrNull;
    final subtitle = current != null
        ? '${current.displayIcon} ${current.title}'
        : '기본 일기장';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.bookmark_border, color: AppColors.textSecondary),
        title: const Text('기본 일기장'),
        subtitle: Text('빠른 기록(+)이 쓰이는 곳 · $subtitle'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () async {
          final picked = await showModalBottomSheet<String>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('기본 일기장 선택',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  for (final j in journals)
                    ListTile(
                      leading: Text(j.displayIcon,
                          style: const TextStyle(fontSize: 20)),
                      title: Text(j.title),
                      subtitle: Text(j.type.label),
                      trailing: j.journalId == defaultId
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, j.journalId),
                    ),
                ],
              ),
            ),
          );
          if (picked != null) {
            await ref.read(defaultJournalProvider.notifier).set(picked);
          }
        },
      ),
    );
  }
}

/// Exports every journal + entry as Markdown and copies it to the clipboard
/// (a no-dependency backup the user can paste into Notes, email, etc.).
class _ExportTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.ios_share, color: AppColors.textSecondary),
        title: const Text('기록 내보내기'),
        subtitle: const Text('모든 기록을 텍스트로 클립보드에 복사'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () async {
          final journals = ref.read(journalsProvider).asData?.value ?? const [];
          final entries = ref.read(entriesProvider).asData?.value ?? const [];
          final messenger = ScaffoldMessenger.of(context);
          if (entries.isEmpty) {
            messenger.showSnackBar(
              const SnackBar(content: Text('내보낼 기록이 없어요')),
            );
            return;
          }
          final text = exportMarkdown(journals, entries, DateTime.now());
          await Clipboard.setData(ClipboardData(text: text));
          messenger.showSnackBar(
            SnackBar(content: Text('${entries.length}개 기록을 클립보드에 복사했어요')),
          );
        },
      ),
    );
  }
}

/// Reading text size for the entry detail body. Persisted, with a live
/// preview line inside the picker so the choice is obvious.
class _ReadingTextSizeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(readingTextScaleProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.format_size, color: AppColors.textSecondary),
        title: const Text('읽기 글자 크기'),
        subtitle: Text('기록을 볼 때 본문 크기 · ${readingScaleLabel(scale)}'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () async {
          final picked = await showModalBottomSheet<double>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('읽기 글자 크기',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  for (final s in readingTextScales)
                    ListTile(
                      title: Text('오늘 하루도 수고했어요',
                          style: TextStyle(fontSize: 16 * s)),
                      subtitle: Text(readingScaleLabel(s)),
                      trailing: s == scale
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, s),
                    ),
                ],
              ),
            ),
          );
          if (picked != null) {
            await ref.read(readingTextScaleProvider.notifier).set(picked);
          }
        },
      ),
    );
  }
}

/// Picks how the home journal list is laid out (card list vs. 2/3/4-col grid).
class _HomeLayoutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(homeJournalLayoutProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading:
            const Icon(Icons.grid_view_outlined, color: AppColors.textSecondary),
        title: const Text('홈 일기장 보기'),
        subtitle: Text('홈에서 일기장을 보여주는 방식 · ${current.label}'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () async {
          final picked = await showModalBottomSheet<HomeJournalLayout>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('홈 일기장 보기',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  for (final l in HomeJournalLayout.values)
                    ListTile(
                      title: Text(l.label),
                      trailing: l == current
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, l),
                    ),
                ],
              ),
            ),
          );
          if (picked != null) {
            await ref.read(homeJournalLayoutProvider.notifier).set(picked);
          }
        },
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile(
      {required this.icon, required this.label, this.subtitle, this.onTap});
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(label),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
