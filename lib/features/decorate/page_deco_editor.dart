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

/// 페이지 꾸미기 편집기의 **상태를 소유**하는 컨트롤러.
///
/// Phase 1에서는 편집 위젯이 캔버스를 들고 컨트롤러는 호스트에 읽기/알림만
/// 넘겼지만, Phase 2(글쓰기 탭 통합)에서는 캔버스가 상단에 고정되고 조작 컨트롤은
/// 하단 탭에 흩어지므로, 둘이 같은 상태를 공유해야 한다. 그래서 컨트롤러가
/// 캔버스·선택·시퀀스를 직접 들고 모든 변형 메서드를 노출한다. 변형마다
/// [notifyListeners]가 불려 캔버스([PageDecoCanvas])와 컨트롤(팔레트/툴바)이 함께
/// 다시 그려진다.
class PageDecoEditorController extends ChangeNotifier {
  PageDecoEditorController({PageCanvas? initial})
      : _canvas = initial ?? const PageCanvas();

  PageCanvas _canvas;
  String? _selectedId;
  int _seq = 0;

  /// 스티커 팔레트에서 현재 고른 카테고리 인덱스.
  int categoryIndex = 0;

  PageCanvas get canvas => _canvas;
  String? get selectedId => _selectedId;

  /// 저장할 게 없는 빈 캔버스인지(무늬 plain·바탕색 기본·레이어 없음).
  bool get isBlank =>
      _canvas.layers.isEmpty &&
      _canvas.paper == PaperStyle.plain &&
      _canvas.paperColorValue == null;

  bool get hasLayers => _canvas.layers.isNotEmpty;

  DecoLayer? get selected {
    for (final l in _canvas.layers) {
      if (l.id == _selectedId) return l;
    }
    return null;
  }

  void _mutate(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  /// 편집할 캔버스를 통째로 갈아끼운다(기존 기록 수정 진입 시 프리필용).
  void load(PageCanvas canvas) => _mutate(() {
        _canvas = canvas;
        _selectedId = null;
      });

  void setCategory(int i) => _mutate(() => categoryIndex = i);

  void undoLast() {
    if (_canvas.layers.isEmpty) return;
    _mutate(() {
      final last = _canvas.layers.last.id;
      _canvas = removeLastLayer(_canvas);
      if (_selectedId == last) _selectedId = null;
    });
  }

  void clearLayers() => _mutate(() {
        _canvas = PageCanvas(
          paper: _canvas.paper,
          paperColorValue: _canvas.paperColorValue,
        );
        _selectedId = null;
      });

  void addSticker(String emoji) {
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

  /// 이미 base64 data URL로 인코딩된 사진을 캔버스에 얹는다(사진 획득은 UI가 담당).
  void addPhotoData(String data) {
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
  }

  void addTape(String styleId) {
    final id = 't${_seq++}';
    _mutate(() {
      _canvas = addTapeLayer(_canvas, id, styleId,
          x: 0.5 + (math.Random().nextDouble() - 0.5) * 0.3,
          y: 0.3 + (math.Random().nextDouble() - 0.5) * 0.3);
      _selectedId = id;
    });
  }

  /// 글자 레이어를 올린다(문구·색·굵기는 UI 다이얼로그가 골라 [input]으로 준다).
  void addTextInput(TextLayerInput input) {
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

  void updateTextInput(String id, TextLayerInput input) => _mutate(() {
        _canvas = updateTextLayer(
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
      });

  void applyToSelected(PageCanvas Function(PageCanvas, String) op) {
    final id = _selectedId;
    if (id != null) _mutate(() => _canvas = op(_canvas, id));
  }

  void selectNextLayer() {
    final next = nextLayerId(_canvas, _selectedId);
    if (next != null) _mutate(() => _selectedId = next);
  }

  void selectPreviousLayer() {
    final prev = previousLayerId(_canvas, _selectedId);
    if (prev != null) _mutate(() => _selectedId = prev);
  }

  void deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    _mutate(() {
      _canvas = removeLayer(_canvas, id);
      _selectedId = null;
    });
  }

  void deleteSameKind() {
    final sel = selected;
    if (sel == null) return;
    _mutate(() {
      _canvas = removeLayersOfKind(_canvas, sel.kind);
      _selectedId = null;
    });
  }

  void duplicateSelected() {
    final id = _selectedId;
    if (id == null) return;
    final newId = 'd${_seq++}';
    _mutate(() {
      _canvas = duplicateLayer(_canvas, id, newId);
      _selectedId = newId;
    });
  }

  void deselect() => _mutate(() => _selectedId = null);

  void selectLayer(String id) => _mutate(() {
        _selectedId = id;
        _canvas = bringLayerToFront(_canvas, id);
      });

  void dragLayer(DecoLayer l, double dx, double dy, double w, double h) =>
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

  void setPaperStyle(PaperStyle style) =>
      _mutate(() => _canvas = setPaper(_canvas, style));

  void setPaperColorValue(int? value) =>
      _mutate(() => _canvas = setPaperColor(_canvas, value));
}

/// 갤러리에서 사진을 골라 base64 data URL로 인코딩해 돌려준다(취소/실패 시 null).
/// 캔버스 편집기(놀이터·글쓰기 탭)가 공유하는 사진 획득 헬퍼.
Future<String?> pickCanvasPhotoData(
    BuildContext context, ImagePicker picker) async {
  try {
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    return 'data:${imageMimeForName(x.name)};base64,${base64Encode(bytes)}';
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 불러오지 못했어요')),
      );
    }
    return null;
  }
}

/// 기록 페이지 꾸미기 **편집 화면**(실험용 놀이터 body). 상단에 세로 3:4 캔버스를
/// 전체 폭으로 고정하고, 아래에서 위로 끌어 크기를 조절하는 컨트롤 시트(툴바+속지/
/// 바탕색+팔레트)를 겹쳐 띄운다. 앱바 같은 크롬은 호스트가 제공한다. 캔버스 상태는
/// [controller]가 소유한다.
class PageDecoEditor extends StatefulWidget {
  const PageDecoEditor({
    super.key,
    required this.controller,
    this.titleText = '',
    this.contentText = '',
  });

  final PageDecoEditorController controller;

  /// 종이 맨 위에 굵게 깔 일기 제목(빈 문자열이면 생략).
  final String titleText;

  /// 종이 위에 바탕 글로 깔 본문(제목·본문 모두 비면 안내 문구를 보여준다).
  final String contentText;

  @override
  State<PageDecoEditor> createState() => _PageDecoEditorState();
}

class _PageDecoEditorState extends State<PageDecoEditor> {
  final _picker = ImagePicker();

  // 캔버스가 좌우 이 여백만큼 안쪽에 그려진다(전체 폭 계산에도 쓴다).
  static const double _pagePadding = 16;

  // 세로가 극단적으로 짧은 화면에서 Column이 넘치지 않도록 컨트롤에 최소로
  // 남길 높이(손잡이+한 줄).
  static const double _minControlsVisible = 96;

  // 컨트롤 시트의 현재 높이. 손잡이를 위아래로 끌어 조절한다. null이면 첫
  // 빌드에서 화면 높이의 일정 비율로 초기화한다.
  double? _controlsHeight;

  PageDecoEditorController get _ctrl => widget.controller;

  Future<void> _addPhoto() async {
    final data = await pickCanvasPhotoData(context, _picker);
    if (data != null) _ctrl.addPhotoData(data);
  }

  Future<void> _addText() async {
    final input = await showTextLayerDialog(context);
    if (input != null) _ctrl.addTextInput(input);
  }

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
                    child: PageDecoCanvas(
                      controller: _ctrl,
                      titleText: widget.titleText,
                      contentText: widget.contentText,
                    ),
                  ),
                ),
              ),
            ),
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
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
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
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_ctrl.selected != null) PageDecoToolbar(controller: _ctrl),
                    PaperSelector(
                      paper: _ctrl.canvas.paper,
                      paperColorValue: _ctrl.canvas.paperColorValue,
                      onPaperChanged: _ctrl.setPaperStyle,
                      onColorChanged: _ctrl.setPaperColorValue,
                    ),
                    DecoPalette(
                      categoryIndex: _ctrl.categoryIndex,
                      onCategory: _ctrl.setCategory,
                      onAddPhoto: _addPhoto,
                      onAddText: _addText,
                      onAddTape: _ctrl.addTape,
                      onAddSticker: _ctrl.addSticker,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
