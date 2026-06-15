import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../models/diary_entry.dart';

class EntryCard extends StatelessWidget {
  const EntryCard(this.entry, {super.key, this.onTap});

  final DiaryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('M월 d일 (E)', 'ko').format(entry.createdAt);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (entry.mood != null) ...[
                    Text(entry.mood!.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      entry.title ?? '제목 없음',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(entry.visibility.icon, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.aiSummary ?? entry.content,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.mediaUrls.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _Thumb(entry.mediaUrls.first),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  const Spacer(),
                  ...entry.tags.take(2).map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text('#$t',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.path);
  final String path;

  @override
  Widget build(BuildContext context) {
    const size = 54.0;
    final fallback = Container(
      width: size,
      height: size,
      color: AppColors.primarySoft,
      child: const Icon(Icons.image, size: 20, color: AppColors.primary),
    );
    if (path.startsWith('http')) {
      return Image.network(path,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback);
    }
    return Image.file(File(path),
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback);
  }
}
