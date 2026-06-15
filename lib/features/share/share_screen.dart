import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../entries/entries_provider.dart';

/// Builds a (mock) public share URL for an entry. The backend will issue the
/// real signed URL — see TECH_DESIGN.md `/shares`.
String shareUrlFor(String entryId) {
  final code = entryId.hashCode.toRadixString(36).replaceAll('-', '');
  return 'https://lifelog.app/s/$code';
}

class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final entry = entries.where((e) => e.entryId == entryId).firstOrNull;
    if (entry == null) {
      return const Scaffold(body: Center(child: Text('기록을 찾을 수 없습니다')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('공유 설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('공개 범위',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...EntryVisibility.values.map(
            (v) => _VisibilityTile(
              visibility: v,
              selected: entry.visibility == v,
              onTap: () => ref
                  .read(entriesProvider.notifier)
                  .saveEntry(entry.copyWith(visibility: v)),
            ),
          ),
          const SizedBox(height: 8),
          const _DisabledTile(label: '가족 / 1촌', note: '준비 중'),
          const SizedBox(height: 24),
          if (entry.visibility != EntryVisibility.private)
            _LinkPreview(entry: entry),
        ],
      ),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  const _VisibilityTile({
    required this.visibility,
    required this.selected,
    required this.onTap,
  });

  final EntryVisibility visibility;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(visibility.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(visibility.label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisabledTile extends StatelessWidget {
  const _DisabledTile({required this.label, required this.note});
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, color: AppColors.textHint),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textHint)),
          const Spacer(),
          Text(note, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LinkPreview extends StatelessWidget {
  const _LinkPreview({required this.entry});
  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = shareUrlFor(entry.entryId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('공유 미리보기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title ?? '제목 없음',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(entry.aiSummary ?? entry.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.primaryDark)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: AppColors.primaryDark),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('링크를 복사했어요')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
