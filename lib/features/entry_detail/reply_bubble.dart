import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/journal_member.dart';
import '../journals/members_provider.dart';
import '../journals/members_repository.dart';

/// One reply bubble shown under an entry's thread. Extracted from
/// EntryDetailScreen to keep that file under the size limit.
class ReplyBubble extends ConsumerWidget {
  const ReplyBubble({
    super.key,
    required this.reply,
    required this.locale,
    required this.journalId,
  });
  final DiaryEntry reply;
  final String locale;
  final String journalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat.MMMd(locale).add_jm().format(reply.createdAt);
    final members =
        ref.watch(journalMembersProvider(journalId)).asData?.value ??
            const <JournalMember>[];
    final author =
        members.where((m) => m.userId == reply.userId).firstOrNull;
    final name = author == null
        ? (reply.userId == MembersRepository.meUserId ? '나' : '참여자')
        : (author.isMe ? '나' : author.displayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  name.characters.first,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(reply.content, style: const TextStyle(fontSize: 15, height: 1.4)),
          const SizedBox(height: 6),
          Text(time,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
