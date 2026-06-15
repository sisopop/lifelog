import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../entries/entries_provider.dart';

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value ?? const [];
    final entry = entries.where((e) => e.entryId == entryId).firstOrNull;

    if (entry == null) {
      return const Scaffold(body: Center(child: Text('기록을 찾을 수 없습니다')));
    }

    final date = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(entry.createdAt);
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (v) async {
              if (v == 'edit') {
                context.push('/entry/$entryId/edit');
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('기록 삭제'),
                    content: const Text('이 기록을 삭제할까요? 되돌릴 수 없어요.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(entriesProvider.notifier).delete(entryId);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              if (entry.mood != null) ...[
                Text(entry.mood!.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(entry.title ?? '제목 없음',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              Text(entry.visibility.icon, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$date · ${entry.location ?? ''}',
              style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
          const SizedBox(height: 20),
          if (entry.mediaUrls.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entry.mediaUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final path = entry.mediaUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _photo(path, width: 260, height: 200),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(entry.content, style: const TextStyle(fontSize: 16, height: 1.6)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.aiSummary ?? 'AI 요약을 생성하고 있어요...',
                    style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: entry.tags
                .map((t) => Chip(label: Text('#$t')))
                .toList(),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => context.push('/entry/$entryId/share'),
            icon: const Icon(Icons.share),
            label: const Text('공유하기'),
          ),
        ],
      ),
    );
  }

  /// Renders a local file path or a network URL gracefully.
  Widget _photo(String path, {required double width, required double height}) {
    final isNetwork = path.startsWith('http');
    final errorBox = Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      child: const Icon(Icons.broken_image, color: AppColors.primary),
    );
    if (isNetwork) {
      return Image.network(path,
          width: width, height: height, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => errorBox);
    }
    return Image.file(File(path),
        width: width, height: height, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => errorBox);
  }
}
