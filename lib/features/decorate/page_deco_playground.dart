import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'page_canvas.dart';
import 'page_canvas_view.dart';
import 'sticker_catalog.dart';

/// 기록 페이지 꾸미기 캔버스 에디터.
///
/// [PageCanvas] 모델 위에서 스티커를 올리고·끌고·키우고·돌리는 편집 화면.
/// 두 가지 모드로 쓰인다:
///  - **실험용**(기본): [initial]/[onDone] 없이 열면 저장 없이 자유롭게 만져보는
///    프로토타입(설정 → "페이지 꾸미기(실험)").
///  - **실기록 편집**: [initial]에 기존 캔버스를 주고 [onDone]를 넘기면, 상단
///    "완료" 버튼이 현재 캔버스를 콜백으로 돌려준다(빈 캔버스면 null → 꾸미기 해제).
class PageDecoPlayground extends StatefulWidget {
  const PageDecoPlayground({
    super.key,
    this.initial,
    this.onDone,
    this.title = '페이지 꾸미기 (실험)',
  });

  /// 편집을 시작할 캔버스. null이면 빈 캔버스에서 시작.
  final PageCanvas? initial;

  /// 실기록 편집 모드: "완료" 버튼을 누르면 현재 캔버스를 돌려준다. 캔버스가
  /// 비어 있으면(무늬 plain·레이어 없음) null을 돌려 "꾸미기 없음"을 뜻한다.
  final ValueChanged<PageCanvas?>? onDone;

  final String title;

  @override
  State<PageDecoPlayground> createState() => _PageDecoPlaygroundState();
}

class _PageDecoPlaygroundState extends State<PageDecoPlayground> {
  late PageCanvas _canvas = widget.initial ?? const PageCanvas();
  String? _selectedId;
  int _seq = 0;
  int _categoryIndex = 0;

  /// 저장할 게 없는 빈 캔버스(무늬 없음·레이어 없음)인지.
  bool get _isBlank =>
      _canvas.layers.isEmpty && _canvas.paper == PaperStyle.plain;

  static const _paperLabels = {
    PaperStyle.plain: '무지',
    PaperStyle.lined: '줄',
    PaperStyle.grid: '모눈',
    PaperStyle.dotted: '도트',
  };

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
        title: Text(widget.title),
        actions: [
          if (_canvas.layers.isNotEmpty)
            IconButton(
              tooltip: '모두 지우기',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => setState(() {
                _canvas = PageCanvas(paper: _canvas.paper);
                _selectedId = null;
              }),
            ),
          if (widget.onDone != null)
            TextButton(
              onPressed: () => widget.onDone!(_isBlank ? null : _canvas),
              child: const Text('완료'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _page()),
          if (_selected != null) _selectedToolbar(),
          _paperSelector(),
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
            color: kCanvasPaperCream, // 크림 속지
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
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PageCanvasPaperPainter(_canvas.paper),
                      ),
                    ),
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

  Widget _paperSelector() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          const Text('속지',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          for (final style in PaperStyle.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(_paperLabels[style]!),
                selected: _canvas.paper == style,
                onSelected: (_) =>
                    setState(() => _canvas = setPaper(_canvas, style)),
              ),
            ),
        ],
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
