import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../models/diary_entry.dart';
import 'photo.dart';

class EntryCard extends StatelessWidget {
  const EntryCard(
    this.entry, {
    super.key,
    this.onTap,
    this.authorName,
    this.journalName,
    this.journalIcon,
  });

  final DiaryEntry entry;
  final VoidCallback? onTap;

  /// Author label for shared journals (커플/교환). Null → not shown.
  final String? authorName;

  /// Owning journal name, shown as a small label on mixed lists (기록/검색).
  /// Null → not shown (e.g. a single-journal detail view).
  final String? journalName;

  /// Emoji/icon of the owning journal, shown beside [journalName].
  final String? journalIcon;

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
              if (journalName != null) ...[
                Row(
                  children: [
                    if (journalIcon != null) ...[
                      Text(journalIcon!, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        journalName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
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
                  if (entry.isFavorite) ...[
                    const Icon(Icons.star, size: 15, color: Colors.amber),
                    const SizedBox(width: 4),
                  ],
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
                      child: PhotoView(entry.mediaUrls.first,
                          width: 54, height: 54),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (authorName != null) ...[
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        authorName!.characters.first,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('$authorName · ',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600)),
                  ],
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
