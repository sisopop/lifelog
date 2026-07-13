import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/photo.dart';
import 'page_canvas.dart';
import 'page_canvas_view.dart';
import 'page_deco_palette.dart';
import 'paper_page.dart';
import 'paper_selector.dart';
import 'text_color_catalog.dart';
import 'text_layer_dialog.dart';

part 'page_deco_editor_canvas.dart';
part 'page_deco_editor_toolbar.dart';

/// 재사용 가능한 페이지 꾸미기 편집기의 상태를 밖(호스트)에서 읽고 조작하는
/// 컨트롤러. [PageDecoEditor]는 캔버스 상태를 스스로 소유하지만, 이 컨트롤러를
/// 넘겨 주면 호스트(예: [PageDecoPlayground]의 AppBar, 앞으로는 글쓰기 화면의
/// 탭바)가 현재 캔버스를 읽거나 "되돌리기/모두 지우기"를 실행할 수 있다.
/// 레이어가 바뀔 때마다 [notifyListeners]가 불려, 호스트 UI(취소/지우기 버튼
/// 노출 등)가 자동으로 갱신된다.
class PageDecoEditorController extends ChangeNotifier {
  _PageDecoEditorState? _state;

  void _bind(_PageDecoEditorState s) => _state = s;
  void _unbind(_PageDecoEditorState s) {
    if (_state == s) _state = null;
  }

  /// 편집기 상태가 캔버스를 바꿀 때 호스트 UI(AppBar 등)를 갱신하도록 알린다.
  /// [notifyListeners]는 보호 멤버라 편집기 상태에서 직접 못 부르므로, 이
  /// 컨트롤러 안(ChangeNotifier 서브클래스)에서 감싸 노출한다.
  void _notify() => notifyListeners();

  /// 현재 편집 중인 캔버스(아직 붙지 않았으면 기본 빈 캔버스).
  PageCanvas get canvas => _state?._canvas ?? const PageCanvas();

  /// 저장할 게 없는 빈 캔버스인지(무늬 plain·바탕색 기본·레이어 없음).
  bool get isBlank => _state?._isBlank ?? true;

  /// 되돌리기/모두 지우기 버튼을 보일지 판단할 때 쓴다.
  bool get hasLayers => _state?._canvas.layers.isNotEmpty ?? false;

  /// 마지막에 올린 레이어 하나를 되돌린다.
  void undoLast() => _state?._undoLast();

  /// 모든 레이어를 지운다(속지·바탕색은 유지).
  void clearLayers() => _state?._clearLayers();
}

/// 기록 페이지 꾸미기 **편집 캔버스**(스티커/사진/테이프/글자 레이어를 올리고·
/// 끌고·키우고·돌리는 부분)만 떼어낸 재사용 위젯. 예전엔 이 로직이 전부
/// [PageDecoPlayground] 안에 있었지만, 글쓰기 화면에 탭으로 통합하려고 캔버스+
/// 툴바+제스처만 이 위젯으로 추출했다(동작·UI는 이전과 동일).
///
/// 화면 상단에 세로 3:4 캔버스를 전체 폭으로 고정하고, 아래에서 위로 끌어 크기를
/// 조절하는 컨트롤 시트(툴바+속지/바탕색+팔레트)를 겹쳐 띄운다. 앱바 같은 크롬은
/// 호스트가 제공한다.
class PageDecoEditor extends StatefulWidget {
  const PageDecoEditor({
    super.key,
    this.initial,
    this.controller,
    this.titleText = '',
    this.contentText = '',
  });

  /// 편집을 시작할 캔버스. null이면 빈 캔버스에서 시작.
  final PageCanvas? initial;

  /// 호스트가 캔버스를 읽거나 되돌리기/지우기를 하려면 넘긴다(선택).
  final PageDecoEditorController? controller;

  /// 종이 맨 위에 굵게 깔 일기 제목(빈 문자열이면 생략).
  final String titleText;

  /// 종이 위에 바탕 글로 깔 본문(제목·본문 모두 비면 안내 문구를 보여준다).
  final String contentText;

  @override
  State<PageDecoEditor> createState() => _PageDecoEditorState();
}

class _PageDecoEditorState extends State<PageDecoEditor> {
  late PageCanvas _canvas = widget.initial ?? const PageCanvas();
  String? _selectedId;
  int _seq = 0;
  int _categoryIndex = 0;
  final _picker = ImagePicker();

  // 캔버스가 좌우 이 여백만큼 안쪽에 그려진다(전체 폭 계산에도 쓴다).
  static const double _pagePadding = 16;

  // 세로가 극단적으로 짧은 화면에서 Column이 넘치지 않도록 컨트롤에 최소로
  // 남길 높이(손잡이+한 줄).
  static const double _minControlsVisible = 96;

  // 컨트롤 시트의 현재 높이. 손잡이를 위아래로 끌어 조절한다. null이면 첫
  // 빌드에서 화면 높이의 일정 비율로 초기화한다.
  double? _controlsHeight;

  @override
  void initState() {
    super.initState();
    widget.controller?._bind(this);
    // 편집 모드로 기존 캔버스를 열면 첫 프레임엔 컨트롤러가 아직 레이어 유무를
    // 호스트에 알리지 못하므로(바인딩 직후라 notify 없음), 한 번 알려 AppBar의
    // 되돌리기/지우기 버튼이 초기부터 올바르게 뜨게 한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller?._notify();
    });
  }

  @override
  void dispose() {
    widget.controller?._unbind(this);
    super.dispose();
  }

  /// setState + 컨트롤러 알림. 캔버스를 바꾸는 모든 조작은 이걸 거쳐, 호스트의
  /// AppBar/탭바가 레이어 유무에 맞춰 갱신되게 한다.
  void _mutate(VoidCallback fn) {
    setState(fn);
    widget.controller?._notify();
  }

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

  void _undoLast() {
    if (_canvas.layers.isEmpty) return;
    _mutate(() {
      final last = _canvas.layers.last.id;
      _canvas = removeLastLayer(_canvas);
      if (_selectedId == last) _selectedId = null;
    });
  }

  void _clearLayers() {
    _mutate(() {
      _canvas = PageCanvas(
        paper: _canvas.paper,
        paperColorValue: _canvas.paperColorValue,
      );
      _selectedId = null;
    });
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
    _mutate(() {
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
      _mutate(() {
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
    _mutate(() {
      _canvas = addTapeLayer(_canvas, id, styleId,
          x: 0.5 + (math.Random().nextDouble() - 0.5) * 0.3,
          y: 0.3 + (math.Random().nextDouble() - 0.5) * 0.3);
      _selectedId = id;
    });
  }

  /// 글자(메모) 조각을 올린다. 다이얼로그로 문구·잉크 색·굵기를 골라 얹는다.
  Future<void> _addText() async {
    final input = await showTextLayerDialog(context);
    if (input == null) return;
    final id = 'x${_seq++}';
    _mutate(() {
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

  /// 이미 올린 글자 레이어의 문구·색·굵기·형광펜을 다시 골라 고친다.
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
    _mutate(() {
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

  // 선택된 레이어 id에 캔버스 순수함수를 적용해 상태를 갱신한다. 툴바가 공유.
  void _applyToSelected(PageCanvas Function(PageCanvas, String) op) {
    final id = _selectedId;
    if (id != null) _mutate(() => _canvas = op(_canvas, id));
  }

  // 겹쳐 놓아 탭으로 고르기 힘든 레이어를 z 순서(아래→위)로 순회 선택한다.
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
    _mutate(() {
      _canvas = removeLayer(_canvas, id);
      _selectedId = null;
    });
  }

  // 선택 레이어와 같은 종류(스티커/사진/테이프/글자)를 한 번에 모두 지운다.
  void _deleteSameKind() {
    final sel = _selected;
    if (sel == null) return;
    _mutate(() {
      _canvas = removeLayersOfKind(_canvas, sel.kind);
      _selectedId = null;
    });
  }

  // 선택 레이어를 복제해 새로 만든 레이어를 선택 상태로 둔다.
  void _duplicateSelected() {
    final id = _selectedId;
    if (id == null) return;
    final newId = 'd${_seq++}';
    _mutate(() {
      _canvas = duplicateLayer(_canvas, id, newId);
      _selectedId = newId;
    });
  }

  // ── 캔버스(_DecoCanvas)가 호출하는 제스처 처리 ────────────────────────────
  void _deselect() => _mutate(() => _selectedId = null);

  void _selectLayer(String id) => _mutate(() {
        _selectedId = id;
        _canvas = bringLayerToFront(_canvas, id);
      });

  void _dragLayer(DecoLayer l, double dx, double dy, double w, double h) =>
      _mutate(() {
        _selectedId = l.id;
        _canvas = replaceLayer(
          _canvas,
          l.copyWith(
            x: clampUnit(l.x + dx / w),
            y: clampUnit(l.y + dy / h),
          ),
        );
      });

  // ── 속지/바탕색 ─────────────────────────────────────────────────────────
  void _setPaperStyle(PaperStyle style) =>
      _mutate(() => _canvas = setPaper(_canvas, style));

  void _setPaperColorValue(int? value) =>
      _mutate(() => _canvas = setPaperColor(_canvas, value));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outer) {
        // 캔버스 폭 = 화면 폭 - 좌우 패딩, 높이 = 폭 / (3/4)(세로 페이지). 이
        // 크기로 상단에 고정한다. 캔버스는 항상 전체 폭이고, 컨트롤 시트는 그
        // 위에 겹쳐 뜨는 오버레이라 무엇을 올려도 캔버스 폭은 그대로다.
        final fullWidth = outer.maxWidth - _pagePadding * 2;
        final fullWidthHeight = fullWidth / kPageAspectRatio;
        final maxPageHeight =
            (outer.maxHeight - _pagePadding * 2).clamp(0.0, double.infinity);
        final pageHeight = math.min(fullWidthHeight, maxPageHeight);
        final pageWidth = pageHeight * kPageAspectRatio;

        final minControls = _minControlsVisible;
        final maxControls =
            (outer.maxHeight * 0.85).clamp(minControls, outer.maxHeight);
        final controlsHeight = (_controlsHeight ?? outer.maxHeight * 0.38)
            .clamp(minControls, maxControls);

        return Stack(
          children: [
            // 캔버스: 상단에 전체 폭으로 고정(시트에 가려지는 아래쪽은 시트를
            // 내리면 다시 드러난다).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(_pagePadding),
                child: Center(
                  child: SizedBox(
                    width: pageWidth,
                    height: pageHeight,
                    child: _DecoCanvas(this),
                  ),
                ),
              ),
            ),
            // 컨트롤 시트: 아래에서 위로 끌어올렸다 내렸다 하는 오버레이.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: controlsHeight,
              child: _controlsSheet(controlsHeight, minControls, maxControls),
            ),
          ],
        );
      },
    );
  }

  /// 아래에서 위로 끌어 크기를 조절하는 컨트롤 시트(툴바+속지+팔레트).
  Widget _controlsSheet(
      double height, double minControls, double maxControls) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 끌어서 크기 조절하는 손잡이. 넉넉한 터치 영역(24px)에 작은 그립 바.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => setState(() {
              _controlsHeight =
                  (height - d.delta.dy).clamp(minControls, maxControls);
            }),
            child: SizedBox(
              height: 24,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selected != null) _SelectedToolbar(this),
                  PaperSelector(
                    paper: _canvas.paper,
                    paperColorValue: _canvas.paperColorValue,
                    onPaperChanged: _setPaperStyle,
                    onColorChanged: _setPaperColorValue,
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
}
