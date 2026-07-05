import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/photo.dart';
import 'content_flow_demo.dart';
import 'page_canvas.dart';
import 'page_canvas_view.dart';
import 'page_deco_palette.dart';
import 'paper_page.dart';
import 'paper_selector.dart';
import 'text_color_catalog.dart';
import 'text_layer_dialog.dart';

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
    this.contentText = '',
  });

  /// 편집을 시작할 캔버스. null이면 빈 캔버스에서 시작.
  final PageCanvas? initial;

  /// 지금까지 쓴 본문. 종이 위에 바탕 글로 깔아, 스티커를 "쓴 글 주변"에 놓게 한다
  /// (빈 문자열이면 종이만 꾸미는 실험 모드처럼 안내 문구를 보여준다).
  final String contentText;

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
        italic: input.italic,
        underline: input.underline,
        strike: input.strike,
        shadow: input.shadow,
        bgColorValue: input.bgColorValue,
      );
      _selectedId = id;
    });
  }

  /// 이미 올린 글자 레이어의 문구·색·굵기·형광펜을 다시 골라 고친다(오타 수정 등).
  Future<void> _editText(DecoLayer l) async {
    final input = await showTextLayerDialog(
      context,
      initial: TextLayerInput(
        l.value,
        l.colorValue ?? kTextInkColors.first.toARGB32(),
        l.bold,
        l.bgColorValue,
        italic: l.italic,
        underline: l.underline,
        strike: l.strike,
        shadow: l.shadow,
      ),
    );
    if (input == null) return;
    setState(() {
      _canvas = updateTextLayer(
        _canvas,
        l.id,
        input.text,
        colorValue: input.colorValue,
        bold: input.bold,
        italic: input.italic,
        underline: input.underline,
        strike: input.strike,
        shadow: input.shadow,
        bgColorValue: input.bgColorValue,
      );
    });
  }

  // 선택된 레이어 id에 캔버스 순수함수를 적용해 상태를 갱신한다. 툴바 버튼들이 공유.
  void _applyToSelected(PageCanvas Function(PageCanvas, String) op) {
    final id = _selectedId;
    if (id != null) setState(() => _canvas = op(_canvas, id));
  }

  // 겹쳐 놓아 탭으로 고르기 힘든 레이어를 z 순서(아래→위)로 순회 선택한다.
  // 맨 위 다음은 다시 맨 아래로 순환한다.
  void _selectNextLayer() {
    final next = nextLayerId(_canvas, _selectedId);
    if (next != null) setState(() => _selectedId = next);
  }

  // "다음 레이어"의 역방향. 지나친 레이어로 z 순서를 거슬러 되돌아온다.
  void _selectPreviousLayer() {
    final prev = previousLayerId(_canvas, _selectedId);
    if (prev != null) setState(() => _selectedId = prev);
  }

  void _deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    setState(() {
      _canvas = removeLayer(_canvas, id);
      _selectedId = null;
    });
  }

  // 선택 레이어와 같은 종류(스티커/사진/테이프/글자)를 한 번에 모두 지운다.
  void _deleteSameKind() {
    final sel = _selected;
    if (sel == null) return;
    setState(() {
      _canvas = removeLayersOfKind(_canvas, sel.kind);
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
              tooltip: '실행 취소',
              icon: const Icon(Icons.undo),
              onPressed: () => setState(() {
                final last = _canvas.layers.last.id;
                _canvas = removeLastLayer(_canvas);
                if (_selectedId == last) _selectedId = null;
              }),
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
          // 페이지가 남는 세로 공간을 전부 차지하게 한다. 전엔 flex 3:2로 고정
          // 배분해 컨트롤이 항상 화면의 2/5를 차지했는데, 좁은 화면(특히 웹
          // 브라우저는 주소창 등으로 세로 여유가 더 줄어든다)에서는 그 3/5조차
          // AspectRatio(세로 3:4)가 필요로 하는 높이에 못 미쳐 페이지가 폭을 다
          // 못 쓰고 작게 보였다(사용자 신고: "꾸미기 페이지가 전체화면이 아닌
          // 조그맣게 나옴"). 컨트롤을 아래 고정 높이(스크롤 가능)로 압축해
          // 페이지에 필요한 높이를 최대한 돌려준다. 스티커 드래그는 여전히
          // 페이지 영역 안에서만 일어나 컨트롤의 세로 스크롤 제스처와 충돌하지
          // 않는다(컨트롤 스크롤 영역과 분리된 채 유지).
          Expanded(
            child: Center(child: _page()),
          ),
          if (_selected != null) _selectedToolbar(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PaperSelector(
                    paper: _canvas.paper,
                    paperColorValue: _canvas.paperColorValue,
                    onPaperChanged: (style) =>
                        setState(() => _canvas = setPaper(_canvas, style)),
                    onColorChanged: (value) =>
                        setState(() => _canvas = setPaperColor(_canvas, value)),
                  ),
                  DecoPalette(
                    categoryIndex: _categoryIndex,
                    onCategory: (i) => setState(() => _categoryIndex = i),
                    onAddPhoto: _addPhoto,
                    onAddText: _addText,
                    onAddTape: _addTape,
                    onAddSticker: _addSticker,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _page() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        // 상세 합성뷰(DecoratedPageView)와 같은 세로 비율로 그려, 여기서 놓은
        // 위치가 상세에서도 같은 상대 위치에 재현되게 한다(WYSIWYG).
        aspectRatio: kPageAspectRatio,
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
              final baseLines = pageBaseLines(widget.contentText);
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
                    // 쓴 글을 종이 바탕에 깔아, 그 "주변"으로 스티커를 놓게 한다.
                    // 탭/드래그는 아래 GestureDetector·레이어로 통과시킨다.
                    if (baseLines.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              baseLines.join('\n'),
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_canvas.isEmpty && baseLines.isEmpty)
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              // 선택 시 위·오른쪽에 삭제 배지가 앉을 자리를 비운다. 이렇게 해야
              // 배지가 레이어의 히트영역(Stack 크기) 안에 들어와 탭이 먹는다.
              // (Stack 밖으로 삐져나간 요소는 보이기만 하고 탭은 무시된다.)
              padding: selected
                  ? const EdgeInsets.only(top: 14, right: 14)
                  : EdgeInsets.zero,
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
                            border:
                                Border.all(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          )
                        : null,
                    child: decoLayerContent(l, stickerSize: 44 * l.scale),
                  ),
                ),
              ),
            ),
            // 선택된 레이어 위에 바로 뜨는 삭제 배지. 툴바 맨 끝까지 스크롤하지
            // 않아도 눈에 보이는 곳에서 한 번에 지울 수 있게 한다.
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _deleteSelected,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.moodHard,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _selectedToolbar() {
    // 글자 레이어일 때 버튼이 많아(편집 포함) 좁은 화면에서 넘칠 수 있어
    // 가로 스크롤로 감싼다(넘치면 스크롤, 아니면 그대로 보인다).
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: [
          // 삭제를 맨 앞에 둬 선택하자마자 바로 보이게 한다(끝까지 스크롤 불필요).
          _toolBtn(Icons.delete_outline, '삭제', _deleteSelected,
              color: AppColors.moodHard),
          _toolBtn(Icons.layers_outlined, '다음 레이어', _selectNextLayer),
          _toolBtn(Icons.layers_clear_outlined, '이전 레이어',
              _selectPreviousLayer),
          _toolBtn(Icons.remove, '작게',
              () => _applyToSelected((c, id) => stepLayerScale(c, id, -0.15))),
          _toolBtn(Icons.add, '크게',
              () => _applyToSelected((c, id) => stepLayerScale(c, id, 0.15))),
          _toolBtn(Icons.aspect_ratio, '원래크기',
              () => _applyToSelected(resetLayerScale)),
          _toolBtn(Icons.keyboard_arrow_up, '위로',
              () => _applyToSelected((c, id) => nudgeLayer(c, id, 0, -0.05))),
          _toolBtn(Icons.keyboard_arrow_down, '아래로',
              () => _applyToSelected((c, id) => nudgeLayer(c, id, 0, 0.05))),
          _toolBtn(Icons.keyboard_arrow_left, '왼쪽으로',
              () => _applyToSelected((c, id) => nudgeLayer(c, id, -0.05, 0))),
          _toolBtn(Icons.keyboard_arrow_right, '오른쪽으로',
              () => _applyToSelected((c, id) => nudgeLayer(c, id, 0.05, 0))),
          _toolBtn(Icons.opacity, '흐리게',
              () => _applyToSelected((c, id) => stepLayerOpacity(c, id, -0.2))),
          _toolBtn(Icons.opacity_outlined, '진하게',
              () => _applyToSelected((c, id) => stepLayerOpacity(c, id, 0.2))),
          _toolBtn(Icons.format_color_reset_outlined, '또렷하게',
              () => _applyToSelected(resetLayerOpacity)),
          _toolBtn(Icons.rotate_left, '왼쪽',
              () => _applyToSelected((c, id) => stepLayerRotation(c, id, -15))),
          _toolBtn(Icons.rotate_right, '오른쪽',
              () => _applyToSelected((c, id) => stepLayerRotation(c, id, 15))),
          _toolBtn(Icons.rotate_90_degrees_cw, '90°',
              () => _applyToSelected(rotateLayerQuarter)),
          _toolBtn(Icons.straighten, '똑바로',
              () => _applyToSelected(straightenLayer)),
          _toolBtn(Icons.screen_rotation_alt, '직각 정렬',
              () => _applyToSelected(snapLayerRotation)),
          _toolBtn(Icons.center_focus_strong_outlined, '가운데',
              () => _applyToSelected(centerLayer)),
          _toolBtn(Icons.align_horizontal_center, '가로중앙',
              () => _applyToSelected(centerLayerHorizontally)),
          _toolBtn(Icons.align_vertical_center, '세로중앙',
              () => _applyToSelected(centerLayerVertically)),
          _toolBtn(Icons.swap_horiz, '좌우반전',
              () => _applyToSelected(mirrorLayerX)),
          _toolBtn(Icons.swap_vert_outlined, '상하반전',
              () => _applyToSelected(mirrorLayerY)),
          _toolBtn(Icons.transform, '대각반전',
              () => _applyToSelected(mirrorLayerPoint)),
          _toolBtn(Icons.grid_4x4, '격자 정렬',
              () => _applyToSelected(snapLayerToGrid)),
          _toolBtn(Icons.flip, '좌우', () => _applyToSelected(flipLayerX)),
          _toolBtn(Icons.swap_vert, '상하', () => _applyToSelected(flipLayerY)),
          _toolBtn(Icons.restart_alt, '변형 초기화',
              () => _applyToSelected(resetLayerTransform)),
          if (_selected?.kind == DecoKind.text) ...[
            _toolBtn(Icons.edit_outlined, '편집', () => _editText(_selected!)),
            _toolBtn(Icons.format_indent_decrease, '자간-',
                () => _applyToSelected((c, id) => stepLayerLetterSpacing(c, id, -1))),
            _toolBtn(Icons.format_indent_increase, '자간+',
                () => _applyToSelected((c, id) => stepLayerLetterSpacing(c, id, 1))),
            _toolBtn(Icons.format_clear, '자간 초기화',
                () => _applyToSelected(resetLayerLetterSpacing)),
          ],
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
          _toolBtn(Icons.arrow_upward, '앞으로',
              () => _applyToSelected(stepLayerForward)),
          _toolBtn(Icons.arrow_downward, '뒤로',
              () => _applyToSelected(stepLayerBackward)),
          _toolBtn(Icons.flip_to_front, '맨 앞',
              () => _applyToSelected(bringLayerToFront)),
          _toolBtn(Icons.flip_to_back, '맨 뒤',
              () => _applyToSelected(sendLayerToBack)),
          _toolBtn(Icons.delete_sweep_outlined, '종류 삭제', _deleteSameKind,
              color: AppColors.moodHard),
        ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap,
      {Color color = AppColors.textPrimary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        // 툴바가 가로 스크롤이라 넘침 걱정 없이 여유 있는 가로 여백을 준다.
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

}
