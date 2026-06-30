import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'page_canvas.dart';
import 'sticker_catalog.dart';

/// 기록 페이지 꾸미기 **실험용 프로토타입**.
///
/// 아직 저장(DB)·실제 기록 연동은 없다 — 순전히 [PageCanvas] 모델 위에서
/// 스티커를 올리고·끌고·키우고·돌리는 "꾸미는 재미"를 손으로 만져보기 위한
/// 화면이다. 방향이 정해지면 이 조작 흐름을 실제 글쓰기 화면에 이식한다.
class PageDecoPlayground extends StatefulWidget {
  const PageDecoPlayground({super.key});

  @override
  State<PageDecoPlayground> createState() => _PageDecoPlaygroundState();
}

class _PageDecoPlaygroundState extends State<PageDecoPlayground> {
  PageCanvas _canvas = const PageCanvas();
  String? _selectedId;
  int _seq = 0;
  int _categoryIndex = 0;

  DecoLayer? get _selected {
    for (final l in _canvas.layers) {
      if (l.id == _selectedId) return l;
    }
    return null;
  }

  void _addSticker(String emoji) {
    final layer = DecoLayer(
      id: 's${_seq++}',
      kind: DecoKind.sticker,
      value: emoji,
      // 살짝 어긋나게 떨어뜨려 여러 개가 겹쳐 보이지 않게 한다.
      x: 0.5 + (math.Random().nextDouble() - 0.5) * 0.3,
      y: 0.4 + (math.Random().nextDouble() - 0.5) * 0.3,
    );
    setState(() {
      _canvas = addLayer(_canvas, layer);
      _selectedId = layer.id;
    });
  }

  void _editSelected(DecoLayer Function(DecoLayer) f) {
    final sel = _selected;
    if (sel == null) return;
    setState(() => _canvas = replaceLayer(_canvas, f(sel)));
  }

  void _deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    setState(() {
      _canvas = removeLayer(_canvas, id);
      _selectedId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('페이지 꾸미기 (실험)'),
        actions: [
          if (_canvas.layers.isNotEmpty)
            IconButton(
              tooltip: '모두 지우기',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => setState(() {
                _canvas = const PageCanvas();
                _selectedId = null;
              }),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _page()),
          if (_selected != null) _selectedToolbar(),
          _palette(),
        ],
      ),
    );
  }

  Widget _page() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF7), // 크림 속지
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selectedId = null),
                child: Stack(
                  children: [
                    if (_canvas.isEmpty)
                      const Center(
                        child: Text(
                          '아래 스티커를 눌러 올려보세요\n끌어서 옮기고, 골라서 키우거나 돌릴 수 있어요',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textHint, height: 1.5),
                        ),
                      ),
                    for (final l in layersByZ(_canvas)) _layerWidget(l, w, h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _layerWidget(DecoLayer l, double w, double h) {
    final selected = l.id == _selectedId;
    return Positioned(
      left: l.x * w,
      top: l.y * h,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: () => setState(() {
            _selectedId = l.id;
            _canvas = bringLayerToFront(_canvas, l.id);
          }),
          onPanUpdate: (d) => setState(() {
            _selectedId = l.id;
            _canvas = replaceLayer(
              _canvas,
              l.copyWith(
                x: clampUnit(l.x + d.delta.dx / w),
                y: clampUnit(l.y + d.delta.dy / h),
              ),
            );
          }),
          child: Transform.rotate(
            angle: l.rotation * math.pi / 180,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: selected
                  ? BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Text(
                l.value,
                style: TextStyle(fontSize: 44 * l.scale),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedToolbar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolBtn(Icons.remove, '작게', () => _editSelected((l) =>
              l.copyWith(scale: (l.scale - 0.15).clamp(0.4, 4.0)))),
          _toolBtn(Icons.add, '크게', () => _editSelected((l) =>
              l.copyWith(scale: (l.scale + 0.15).clamp(0.4, 4.0)))),
          _toolBtn(Icons.rotate_right, '회전', () => _editSelected((l) =>
              l.copyWith(rotation: (l.rotation + 15) % 360))),
          _toolBtn(Icons.flip_to_front, '맨 앞', () {
            final id = _selectedId;
            if (id != null) {
              setState(() => _canvas = bringLayerToFront(_canvas, id));
            }
          }),
          _toolBtn(Icons.delete_outline, '삭제', _deleteSelected,
              color: AppColors.moodHard),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap,
      {Color color = AppColors.textPrimary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _palette() {
    final category = kStickerCatalog[_categoryIndex];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < kStickerCatalog.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(kStickerCatalog[i].label),
                      selected: i == _categoryIndex,
                      onSelected: (_) => setState(() => _categoryIndex = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final emoji in category.stickers)
                InkWell(
                  onTap: () => _addSticker(emoji),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(emoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
