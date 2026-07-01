import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/photo.dart';
import 'content_flow_demo.dart';
import 'page_canvas.dart';
import 'page_canvas_view.dart';
import 'paper_selector.dart';
import 'sticker_catalog.dart';
import 'text_layer_dialog.dart';
import 'washi_tape_catalog.dart';

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
  final _picker = ImagePicker();

  /// 저장할 게 없는 빈 캔버스(무늬 없음·바탕색 기본·레이어 없음)인지.
  bool get _isBlank =>
      _canvas.layers.isEmpty &&
      _canvas.paper == PaperStyle.plain &&
      _canvas.paperColorValue == null;

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

  /// 갤러리에서 사진을 골라 캔버스에 얹는다. base64 data URL로 인코딩해
  /// (기록 사진과 같은 방식) 캔버스 JSON에 그대로 영속·모든 플랫폼에서 렌더된다.
  Future<void> _addPhoto() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final data = 'data:${imageMimeForName(x.name)};base64,'
          '${base64Encode(bytes)}';
      if (!mounted) return;
      final id = 'p${_seq++}';
      setState(() {
        _canvas = addPhotoLayer(
          _canvas,
          id,
          data,
          x: 0.5 + (math.Random().nextDouble() - 0.5) * 0.2,
          y: 0.4 + (math.Random().nextDouble() - 0.5) * 0.2,
        );
        _selectedId = id;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러오지 못했어요')),
        );
      }
    }
  }

  /// 마스킹테이프 한 조각을 살짝 어긋난 위치에 얹는다.
  void _addTape(String styleId) {
    final id = 't${_seq++}';
    setState(() {
      _canvas = addTapeLayer(_canvas, id, styleId,
          x: 0.5 + (math.Random().nextDouble() - 0.5) * 0.3,
          y: 0.3 + (math.Random().nextDouble() - 0.5) * 0.3);
      _selectedId = id;
    });
  }

  /// 글자(메모) 조각을 올린다. 다이얼로그로 문구·잉크 색·굵기를 골라 중앙에 얹는다.
  Future<void> _addText() async {
    final input = await showTextLayerDialog(context);
    if (input == null) return;
    final id = 'x${_seq++}';
    setState(() {
      _canvas = addTextLayer(
        _canvas,
        id,
        input.text,
        colorValue: input.colorValue,
        bold: input.bold,
        bgColorValue: input.bgColorValue,
      );
      _selectedId = id;
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
          if (widget.onDone == null)
            IconButton(
              tooltip: '글 흐름 미리보기',
              icon: const Icon(Icons.view_agenda_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContentFlowDemo()),
              ),
            ),
          if (_canvas.layers.isNotEmpty)
            IconButton(
              tooltip: '모두 지우기',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => setState(() {
                _canvas = PageCanvas(
                  paper: _canvas.paper,
                  paperColorValue: _canvas.paperColorValue,
                );
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
          PaperSelector(
            paper: _canvas.paper,
            paperColorValue: _canvas.paperColorValue,
            onPaperChanged: (style) =>
                setState(() => _canvas = setPaper(_canvas, style)),
            onColorChanged: (value) =>
                setState(() => _canvas = setPaperColor(_canvas, value)),
          ),
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
            color: _canvas.paperColorValue != null
                ? Color(_canvas.paperColorValue!)
                : kCanvasPaperCream, // 기본 크림 속지
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
              child: decoLayerContent(l, stickerSize: 44 * l.scale),
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
          _toolBtn(Icons.copy_all_outlined, '복제', () {
            final id = _selectedId;
            if (id != null) {
              final newId = 'd${_seq++}';
              setState(() {
                _canvas = duplicateLayer(_canvas, id, newId);
                _selectedId = newId;
              });
            }
          }),
          _toolBtn(Icons.flip_to_front, '맨 앞', () {
            final id = _selectedId;
            if (id != null) {
              setState(() => _canvas = bringLayerToFront(_canvas, id));
            }
          }),
          _toolBtn(Icons.flip_to_back, '맨 뒤', () {
            final id = _selectedId;
            if (id != null) {
              setState(() => _canvas = sendLayerToBack(_canvas, id));
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
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _addPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: const Text('사진 추가'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _addText,
                icon: const Icon(Icons.text_fields, size: 20),
                label: const Text('글자'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('테이프',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                for (final t in kWashiTapes)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _addTape(t.id),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 46,
                        height: 24,
                        decoration: BoxDecoration(
                          color: t.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
