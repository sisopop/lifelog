import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/journal.dart';
import '../journals/journals_provider.dart';
import 'cover_band.dart';
import 'cover_binding.dart';
import 'cover_clip.dart';
import 'cover_corner.dart';
import 'cover_font.dart';
import 'cover_palette.dart';
import 'cover_pattern.dart';
import 'cover_ribbon.dart';
import 'cover_tab.dart';
import 'cover_texture.dart';
import 'cover_theme.dart';
import 'journal_cover.dart';

part 'cover_decorate_sections.dart';

/// "꾸미기" 바텀시트를 엽니다 — 일기장 표지 꾸미기.
/// 책장에서 일기장을 길게 눌러 진입합니다. 칩을 탭하면 미리보기에 바로 보이고,
/// 우측 상단 "저장"을 눌러야 실제로 반영·저장됩니다(안 누르고 내리면 취소).
/// 섹션 빌더(칩 목록)는 분량이 커서 cover_decorate_sections.dart(part)로 분리.
Future<void> showCoverDecorateSheet(
  BuildContext context,
  WidgetRef ref,
  Journal journal,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CoverDecorateSheet(journal: journal),
  );
}

class _CoverDecorateSheet extends ConsumerStatefulWidget {
  const _CoverDecorateSheet({required this.journal});
  final Journal journal;

  @override
  ConsumerState<_CoverDecorateSheet> createState() => _CoverDecorateSheetState();
}

class _CoverDecorateSheetState extends ConsumerState<_CoverDecorateSheet> {
  late int _color = widget.journal.coverColor;
  late String _icon = widget.journal.displayIcon;
  late final String _pattern =
      normalizeCoverPattern(widget.journal.coverPattern);
  late String _binding = normalizeCoverBinding(widget.journal.coverBinding);
  late String _corner = normalizeCoverCorner(widget.journal.coverCorner);
  late String _band = normalizeCoverBand(widget.journal.coverBand);
  late String _ribbon = normalizeCoverRibbon(widget.journal.coverRibbon);
  late String _clip = normalizeCoverClip(widget.journal.coverClip);
  late String _tab = normalizeCoverTab(widget.journal.coverTab);
  late String _texture = normalizeCoverTexture(widget.journal.coverTexture);
  late String _font = normalizeCoverFont(widget.journal.coverFont);

  // Chip taps only update the live preview (local state). Nothing is written
  // to the DB until "저장" is tapped — this batches every change into a single
  // edit() and avoids per-tap async writes racing on web.
  void _pick(int c) => setState(() => _color = c);
  void _pickIcon(String e) => setState(() => _icon = e);
  void _pickBinding(String b) => setState(() => _binding = b);
  void _pickCorner(String c) => setState(() => _corner = c);
  void _pickBand(String b) => setState(() => _band = b);
  void _pickRibbon(String r) => setState(() => _ribbon = r);
  void _pickClip(String c) => setState(() => _clip = c);
  void _pickTab(String t) => setState(() => _tab = t);
  void _pickTexture(String t) => setState(() => _texture = t);
  void _pickFont(String f) => setState(() => _font = f);

  void _pickTheme(CoverTheme theme) {
    setState(() {
      _color = theme.color;
      _icon = theme.icon;
      _texture = theme.texture;
      _binding = theme.binding;
      _corner = theme.corner;
      _band = theme.band;
      _ribbon = theme.ribbon;
      _clip = theme.clip;
      _tab = theme.tab;
    });
  }

  /// Persist every layer at once, then close. Capturing the messenger before
  /// popping avoids using a deactivated context.
  void _save() {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    ref.read(journalsProvider.notifier).edit(
          widget.journal.copyWith(
            coverColor: _color,
            icon: _icon,
            coverPattern: _pattern,
            coverBinding: _binding,
            coverCorner: _corner,
            coverBand: _band,
            coverRibbon: _ribbon,
            coverClip: _clip,
            coverTab: _tab,
            coverTexture: _texture,
            coverFont: _font,
          ),
        );
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('표지를 저장했어요')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.journal;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 고정 헤더: 손잡이·제목·미리보기. 아래 칩만 스크롤되어 표지에
          // 적용되는 모습을 스크롤하지 않고도 실시간으로 볼 수 있다.
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('표지 꾸미기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('저장',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 110,
              height: 140,
              child: JournalCover(
                color: _color,
                icon: _icon,
                pattern: _pattern,
                binding: _binding,
                corner: _corner,
                band: _band,
                ribbon: _ribbon,
                clip: _clip,
                tab: _tab,
                texture: _texture,
                titleFont: coverFontFamily(_font),
                title: j.title,
                radius: 14,
                iconSize: 30,
                titleSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  top: 20, bottom: 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections(j),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
