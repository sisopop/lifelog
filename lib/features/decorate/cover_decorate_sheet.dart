import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/journal.dart';
import '../journals/journals_provider.dart';
import 'cover_band.dart';
import 'cover_binding.dart';
import 'cover_clip.dart';
import 'cover_corner.dart';
import 'cover_palette.dart';
import 'cover_pattern.dart';
import 'cover_ribbon.dart';
import 'cover_tab.dart';
import 'cover_texture.dart';
import 'cover_theme.dart';
import 'journal_cover.dart';

/// "꾸미기" 바텀시트를 엽니다 — 일기장 표지 꾸미기(v1: 표지 색).
/// 책장에서 일기장을 길게 눌러 진입합니다. 색을 탭하면 즉시 저장·반영됩니다.
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

  void _pick(int c) {
    if (c == _color) return;
    setState(() => _color = c);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(coverColor: c));
  }

  void _pickIcon(String e) {
    if (e == _icon) return;
    setState(() => _icon = e);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(icon: e));
  }

  void _pickBinding(String b) {
    if (b == _binding) return;
    setState(() => _binding = b);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(coverBinding: b));
  }

  void _pickCorner(String c) {
    if (c == _corner) return;
    setState(() => _corner = c);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(coverCorner: c));
  }

  void _pickBand(String b) {
    if (b == _band) return;
    setState(() => _band = b);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(coverBand: b));
  }

  void _pickRibbon(String r) {
    if (r == _ribbon) return;
    setState(() => _ribbon = r);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(coverRibbon: r));
  }

  void _pickClip(String c) {
    if (c == _clip) return;
    setState(() => _clip = c);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(coverClip: c));
  }

  void _pickTab(String t) {
    if (t == _tab) return;
    setState(() => _tab = t);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(coverTab: t));
  }

  void _pickTexture(String t) {
    if (t == _texture) return;
    setState(() => _texture = t);
    ref
        .read(journalsProvider.notifier)
        .edit(widget.journal.copyWith(coverTexture: t));
  }

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
    ref
        .read(journalsProvider.notifier)
        .edit(applyCoverTheme(widget.journal, theme));
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.journal;
    final palette = coverPaletteFor(j.coverColor);
    final icons = coverIconPaletteFor(j.displayIcon);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Text('표지 꾸미기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                title: j.title,
                radius: 14,
                iconSize: 30,
                titleSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('테마',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('한 번에 분위기를 바꿔요',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverThemes.map((t) {
              return GestureDetector(
                onTap: () => _pickTheme(t),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 72,
                      child: JournalCover(
                        color: t.color,
                        icon: t.icon,
                        texture: t.texture,
                        textureScale: 0.7,
                        binding: t.binding,
                        bindingScale: 0.8,
                        corner: t.corner,
                        cornerScale: 0.7,
                        band: t.band,
                        bandScale: 0.7,
                        ribbon: t.ribbon,
                        clip: t.clip,
                        tab: t.tab,
                        radius: 8,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(t.label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('표지 색',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: palette.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => _pick(c),
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
          const SizedBox(height: 20),
          const Text('표지 아이콘',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: icons.map((e) {
              final selected = e == _icon;
              return GestureDetector(
                onTap: () => _pickIcon(e),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: AppColors.primary, width: 2.5)
                        : Border.all(color: AppColors.divider),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('재질',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverTexturePalette.map((t) {
              final selected = t == _texture;
              return GestureDetector(
                onTap: () => _pickTexture(t),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.divider),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: JournalCover(
                          color: _color,
                          icon: '',
                          texture: t,
                          textureScale: 0.7,
                          radius: 8,
                          iconSize: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(coverTextureLabel(t),
                        style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
          // 표지 패턴 섹션은 v1 패턴이 충분히 예쁘지 않아 숨김 처리.
          // 모델/DB/페인터는 그대로 두고, 더 나은 패턴이 준비되면 되살린다.
          const SizedBox(height: 20),
          const Text('제본',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverBindingPalette.map((b) {
              final selected = b == _binding;
              return GestureDetector(
                onTap: () => _pickBinding(b),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.divider),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: JournalCover(
                          color: _color,
                          icon: '',
                          binding: b,
                          bindingScale: 0.8,
                          radius: 8,
                          iconSize: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(coverBindingLabel(b),
                        style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('모서리',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverCornerPalette.map((c) {
              final selected = c == _corner;
              return GestureDetector(
                onTap: () => _pickCorner(c),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.divider),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: JournalCover(
                          color: _color,
                          icon: '',
                          corner: c,
                          cornerScale: 0.7,
                          radius: 8,
                          iconSize: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(coverCornerLabel(c),
                        style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('밴드',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverBandPalette.map((b) {
              final selected = b == _band;
              return GestureDetector(
                onTap: () => _pickBand(b),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.divider),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: JournalCover(
                          color: _color,
                          icon: '',
                          band: b,
                          bandScale: 0.7,
                          radius: 8,
                          iconSize: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(coverBandLabel(b),
                        style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('책갈피',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverRibbonPalette.map((r) {
              final selected = r == _ribbon;
              return GestureDetector(
                onTap: () => _pickRibbon(r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      // 책갈피 끈은 표지 아래로 삐져나오므로 자르지 않고,
                      // 표지를 살짝 띄워 끈이 칩 안에 보이게 한다.
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.divider),
                      ),
                      child: JournalCover(
                        color: _color,
                        icon: '',
                        ribbon: r,
                        radius: 6,
                        iconSize: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(coverRibbonLabel(r),
                        style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('클립',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverClipPalette.map((c) {
              final selected = c == _clip;
              return GestureDetector(
                onTap: () => _pickClip(c),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      // 클립은 표지 윗변 위로 삐져나오므로 자르지 않고,
                      // 표지를 아래로 내려 클립이 칩 안에 보이게 한다.
                      padding: const EdgeInsets.fromLTRB(8, 11, 8, 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.divider),
                      ),
                      child: JournalCover(
                        color: _color,
                        icon: '',
                        clip: c,
                        radius: 6,
                        iconSize: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(coverClipLabel(c),
                        style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('인덱스 탭',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverTabPalette.map((t) {
              final selected = t == _tab;
              return GestureDetector(
                onTap: () => _pickTab(t),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      // 인덱스 탭은 표지 우변 밖으로 삐져나오므로 자르지 않고,
                      // 표지를 왼쪽으로 당겨 탭이 칩 안에 보이게 한다.
                      padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: AppColors.primary, width: 2.5)
                            : Border.all(color: AppColors.divider),
                      ),
                      child: JournalCover(
                        color: _color,
                        icon: '',
                        tab: t,
                        radius: 6,
                        iconSize: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(coverTabLabel(t),
                        style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      ),
    );
  }
}
