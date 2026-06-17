import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/journal.dart';
import 'journals_provider.dart';

/// 3-step new-journal wizard: 타입 → 이름/표지색 → (초대).
/// Type is the first, most defining choice (개인/커플/교환 behave differently);
/// it sets a sensible default cover color and name hint for the next step.
/// See PRD.md §4-1. Invite step is informational in the MVP (couple/exchange
/// invites are wired to the relationship flow later).
class NewJournalScreen extends ConsumerStatefulWidget {
  const NewJournalScreen({super.key});

  @override
  ConsumerState<NewJournalScreen> createState() => _NewJournalScreenState();
}

class _NewJournalScreenState extends ConsumerState<NewJournalScreen> {
  int _step = 0;
  final _titleCtrl = TextEditingController();
  JournalType _type = JournalType.personal;

  static const _palette = [
    0xFF7C6FF0, 0xFFEF6F9E, 0xFF53B7A8, 0xFFF0A35E, 0xFF6FA8F0, 0xFF9B6FF0,
  ];
  int _color = _palette.first;

  /// Default cover color per type (applied when a type is chosen).
  static const _typeColor = {
    JournalType.personal: 0xFF7C6FF0,
    JournalType.couple: 0xFFEF6F9E,
    JournalType.exchange: 0xFF53B7A8,
  };

  String get _nameHint => switch (_type) {
        JournalType.personal => '예: 나의 일기장, 감사일기',
        JournalType.couple => '예: 우리 둘, 사랑 기록',
        JournalType.exchange => '예: 친구와 교환일기',
      };

  void _selectType(JournalType t) =>
      setState(() => _color = _typeColor[(_type = t)]!);

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  bool get _canNext {
    // Step 1 (name) requires a title; type/invite steps are always passable.
    if (_step == 1) return _titleCtrl.text.trim().isNotEmpty;
    return true;
  }

  Future<void> _finish() async {
    final now = DateTime.now();
    await ref.read(journalsProvider.notifier).create(
          Journal(
            journalId: 'jr_${now.microsecondsSinceEpoch}',
            ownerId: 'me',
            type: _type,
            title: _titleCtrl.text.trim(),
            coverColor: _color,
            createdAt: now,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새 일기장 (${_step + 1}/3)'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepDots(step: _step),
              const SizedBox(height: 24),
              Expanded(child: _buildStep()),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canNext
                      ? () {
                          if (_step < 2) {
                            setState(() => _step++);
                          } else {
                            _finish();
                          }
                        }
                      : null,
                  child: Text(_step < 2 ? '다음' : '일기장 만들기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepType(selected: _type, onSelect: _selectType);
      case 1:
        return _StepName(
          controller: _titleCtrl,
          hint: _nameHint,
          color: _color,
          palette: _palette,
          onColor: (c) => setState(() => _color = c),
          onChanged: () => setState(() {}),
        );
      default:
        return _StepInvite(type: _type);
    }
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i <= step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class _StepName extends StatelessWidget {
  const _StepName({
    required this.controller,
    required this.hint,
    required this.color,
    required this.palette,
    required this.onColor,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final int color;
  final List<int> palette;
  final ValueChanged<int> onColor;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('일기장 이름',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          autofocus: true,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 28),
        const Text('표지 색',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: palette.map((c) {
            final selected = c == color;
            return GestureDetector(
              onTap: () => onColor(c),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(color: Colors.black87, width: 3)
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepType extends StatelessWidget {
  const _StepType({required this.selected, required this.onSelect});
  final JournalType selected;
  final ValueChanged<JournalType> onSelect;

  static const _desc = {
    JournalType.personal: '나만 보는 개인 기록. 여러 개 만들 수 있어요.',
    JournalType.couple: '둘만의 일기장. 한 명을 초대해 함께 써요.',
    JournalType.exchange: '친구와 번갈아 쓰는 교환 일기장.',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('어떤 일기장인가요?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...JournalType.values.map((t) {
          final isSel = t == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelect(t),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.divider,
                    width: isSel ? 2 : 1,
                  ),
                  color: isSel ? AppColors.primarySoft.withValues(alpha: 0.4) : null,
                ),
                child: Row(
                  children: [
                    Text(t.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${t.label} 일기장',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(_desc[t]!,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    if (isSel)
                      const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StepInvite extends StatelessWidget {
  const _StepInvite({required this.type});
  final JournalType type;

  @override
  Widget build(BuildContext context) {
    final solo = type == JournalType.personal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(solo ? '준비 완료' : '함께할 사람 초대',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (solo)
          const Text('개인 일기장은 바로 시작할 수 있어요.\n아래 버튼을 눌러 만들어보세요.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5))
        else ...[
          const Text('초대 기반으로만 연결돼요 (양쪽 동의).\n초대는 일기장을 만든 뒤 보낼 수 있어요.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 16),
          _InviteHint(Icons.link, '초대 코드 공유'),
          _InviteHint(Icons.email_outlined, '이메일로 초대'),
          _InviteHint(Icons.contacts_outlined, '연락처에서 선택'),
        ],
      ],
    );
  }
}

class _InviteHint extends StatelessWidget {
  const _InviteHint(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
