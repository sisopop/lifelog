import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';
import '../../shared/models/journal_member.dart';
import 'members_provider.dart';

/// Participants + invite panel for couple/exchange journals.
/// Invites are mocked locally (single device): an invite code is generated
/// and a "데모: 상대 추가" action simulates an accepted invite.
class JournalMembersPanel extends ConsumerWidget {
  const JournalMembersPanel({super.key, required this.journal});
  final Journal journal;

  String get _inviteCode {
    // Stable, human-friendly code derived from the journal id.
    final base = journal.journalId.hashCode.abs().toRadixString(36).toUpperCase();
    return base.padLeft(6, '0').substring(0, 6);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(journalMembersProvider(journal.journalId));
    final members = membersAsync.asData?.value ?? const <JournalMember>[];
    final canInvite = !journal.isArchived;
    final partnerCount = members.where((m) => !m.isMe).length;
    // Couple journals are 1:1; exchange allows more.
    final inviteFull =
        journal.type == JournalType.couple && partnerCount >= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_outlined, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text('참여자 ${members.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...members.map((m) => _MemberTile(
                member: m,
                onRemove: (m.isMe || !canInvite)
                    ? null
                    : () => ref
                        .read(membersControllerProvider)
                        .remove(journal.journalId, m.memberId),
              )),
          if (canInvite && !inviteFull) ...[
            const Divider(height: 24),
            _InviteRow(code: _inviteCode),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_alt),
                label: const Text('데모: 상대 추가'),
                onPressed: () => _addPartner(context, ref),
              ),
            ),
          ] else if (inviteFull)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('커플 일기장은 둘만 함께해요.',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            ),
        ],
      ),
    );
  }

  Future<void> _addPartner(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('상대 추가 (데모)'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '상대 이름',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('추가')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref
          .read(membersControllerProvider)
          .addPartner(journal.journalId, name);
    }
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, this.onRemove});
  final JournalMember member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              member.displayName.characters.first,
              style: const TextStyle(
                  color: AppColors.primaryDark, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              member.isMe ? '${member.displayName} (나)' : member.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (member.role == MemberRole.owner)
            const _RoleBadge('방장')
          else
            const _RoleBadge('참여'),
          if (onRemove != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 16, color: AppColors.textHint),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.link, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        const Text('초대 코드  ', style: TextStyle(color: AppColors.textSecondary)),
        Text(code,
            style: const TextStyle(
                fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        const Spacer(),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.copy, size: 18),
          tooltip: '복사',
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('초대 코드를 복사했어요')),
              );
            }
          },
        ),
      ],
    );
  }
}
