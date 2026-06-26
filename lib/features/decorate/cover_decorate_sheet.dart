import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/journal.dart';
import '../journals/journals_provider.dart';
import 'cover_palette.dart';

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
          _CoverPreview(color: _color, icon: _icon, title: j.title),
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
        ],
      ),
      ),
    );
  }
}

/// Live mini book-cover preview that reflects the picked color immediately.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({
    required this.color,
    required this.icon,
    required this.title,
  });
  final int color;
  final String icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return Center(
      child: Container(
        width: 110,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [c, c.withValues(alpha: 0.78)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 30)),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
