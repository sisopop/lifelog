// 텍스트박스 **리치텍스트 인라인 편집기** + 선택 서식 툴바(flutter_quill 기반).
//
// 선택된 텍스트박스 안에서 바로 글을 쓰고, 글을 드래그해 범위 선택하면 상자 위에
// 작은 편집바가 떠서 굵게/기울임/밑줄/취소선/글자색/형광펜/글꼴/크기를 그 범위에만
// 적용한다. 저장은 Quill Delta JSON([DecoLayer.richValue]) + 검색·통계용 평문([value]).
// 읽기 전용 렌더는 textbox_rich.dart(richTextSpan)가 담당한다.

import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/keyboard_edit.dart';
import 'cover_font.dart';
import 'rich_format_pickers.dart';
import 'textbox_rich.dart';

/// richValue(Quill Delta JSON) 또는 평문 [plain]으로 Quill 문서를 만든다. richValue가
/// 없거나 깨졌으면 평문으로 새 문서를 시작한다(옛 저장본·최초 입력 호환).
Document buildTextBoxQuillDocument(String? richValue, String plain) {
  if (richValue != null && richValue.trim().isNotEmpty) {
    try {
      final ops = jsonDecode(richValue);
      if (ops is List && ops.isNotEmpty) return Document.fromJson(ops);
    } catch (_) {
      // 깨진 JSON → 평문으로 폴백
    }
  }
  final doc = Document();
  if (plain.isNotEmpty) doc.insert(0, plain);
  return doc;
}

/// 선택된 텍스트박스 안에서 직접 글을 입력·서식하는 리치 편집기. 자체
/// [QuillController]를 들고(캔버스가 매 변형마다 다시 그려져도 커서·선택·내용이
/// 유지되도록 StatefulWidget + 부모의 ValueKey로 상태 분리) 값이 바뀔 때마다
/// [onChanged](평문, Delta JSON)로 컨트롤러에 반영한다. 상자 크기(width·height)는
/// 리사이즈에 따라 부모가 갱신해 넘긴다.
class TextBoxRichEditor extends StatefulWidget {
  const TextBoxRichEditor({
    super.key,
    required this.richValue,
    required this.plain,
    required this.fontId,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.baseColor,
    required this.onChanged,
  });

  final String? richValue;
  final String plain;
  final String fontId;
  final double width;
  final double height;
  final double fontSize;
  final Color baseColor;

  /// (평문, Delta JSON) 두 값을 함께 넘긴다.
  final void Function(String plain, String richJson) onChanged;

  @override
  State<TextBoxRichEditor> createState() => _TextBoxRichEditorState();
}

class _TextBoxRichEditorState extends State<TextBoxRichEditor>
    with WidgetsBindingObserver {
  late final QuillController _quill;
  final _focus = FocusNode();
  final _scroll = ScrollController();
  String _lastPlain = '';
  String _lastJson = '';

  // 편집바는 캔버스의 ClipRRect·상자 위치와 무관하게 항상 잘 보이도록 최상위
  // Overlay의 **화면 하단(키보드 바로 위) 고정 위치**에 띄운다. 텍스트박스를 편집
  // 중(포커스)인 동안 계속 표시되고, 서식은 현재 선택 영역/커서에 적용된다.
  OverlayEntry? _bar;

  @override
  void initState() {
    super.initState();
    _quill = QuillController(
      document: buildTextBoxQuillDocument(widget.richValue, widget.plain),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _lastPlain = widget.plain;
    _lastJson = widget.richValue ?? '';
    _quill.addListener(_onQuillChanged);
    _focus.addListener(_syncBar);
    WidgetsBinding.instance.addObserver(this);
    // autoFocus로 첫 프레임 뒤 포커스가 잡히므로, 그 시점에 편집바를 띄운다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBar());
  }

  // 자판이 오르내리면 편집바 표시 여부를 다시 판단한다(자판을 내리면 편집바도
  // 감춰 원래 꾸미기 화면으로 복귀).
  @override
  void didChangeMetrics() => _syncBar();

  // 포커스 + **자판이 실제로 떠 있을 때만** 편집바 Overlay를 띄운다. (안드로이드
  // 뒤로가기는 포커스를 그대로 두고 자판만 내리므로 포커스만으로는 판단 못 한다.)
  void _syncBar() {
    if (!mounted) return;
    final kb = MediaQueryData.fromView(View.of(context)).viewInsets.bottom;
    // 웹은 자판 높이를 보고하지 않아(항상 0) 포커스만으로 판단한다.
    final show = isKeyboardEditing(
      hasFocus: _focus.hasFocus,
      keyboardHeight: kb,
      isWeb: kIsWeb,
    );
    if (show && _bar == null) {
      _bar = OverlayEntry(builder: (ctx) => _barOverlay(ctx));
      Overlay.of(context, rootOverlay: true).insert(_bar!);
    } else if (!show && _bar != null) {
      _bar!.remove();
      _bar = null;
    }
  }

  void _onQuillChanged() {
    // 서식 버튼 활성 상태·색 표시가 커서/선택 이동을 따라가도록 편집바만 다시 그린다.
    _bar?.markNeedsBuild();
    // toPlainText는 끝에 개행을 붙이므로 검색·통계용 평문에서 마지막 개행만 다듬는다.
    final plain = _quill.document.toPlainText().replaceAll(RegExp(r'\n$'), '');
    final json = jsonEncode(_quill.document.toDelta().toJson());
    if (plain != _lastPlain || json != _lastJson) {
      _lastPlain = plain;
      _lastJson = json;
      widget.onChanged(plain, json);
    }
  }

  @override
  void dispose() {
    _bar?.remove();
    _bar = null;
    WidgetsBinding.instance.removeObserver(this);
    _focus.removeListener(_syncBar);
    _quill.removeListener(_onQuillChanged);
    _quill.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // 선택 범위에 [attr]이 이미 있으면 지우고(같은 값이면), 없으면 적용한다(토글).
  // 적용 범위는 _format 규칙(선택 있으면 그 부분, 없으면 글 전체)을 따른다.
  void _toggle(Attribute attr) {
    final cur = _quill.getSelectionStyle().attributes;
    _format(cur.containsKey(attr.key) ? Attribute.clone(attr, null) : attr);
  }

  // 드래그로 선택한 범위가 있으면 그 부분만, 없으면(커서만) **글 전체**에 [attr]을
  // 적용한다(= 전체 기본값 지정). 전체 적용 시 이후 입력도 그 값을 잇도록 커서
  // 토글 스타일도 함께 건다. 인라인 서식이라 마지막 개행은 제외한다.
  void _format(Attribute attr) {
    final sel = _quill.selection;
    if (sel.isValid && !sel.isCollapsed) {
      _quill.formatSelection(attr);
    } else {
      final n = _quill.document.length - 1;
      if (n > 0) _quill.formatText(0, n, attr);
      _quill.formatSelection(attr);
    }
  }

  // 피커에서 고른 값을 현재 선택 범위에 적용한다. 바텀시트가 뜨는 동안 에디터가
  // 포커스를 잃으므로, 열기 전 선택 범위([sel])를 저장했다가 다시 복원한 뒤 서식을
  // 적용하고 포커스를 되돌린다(편집바도 다시 뜨고 결과가 바로 보이도록).
  void _apply(TextSelection sel, RichPick<String?>? res,
      Attribute Function(String? v) build) {
    if (res == null || !mounted) return;
    _focus.requestFocus();
    if (sel.isValid) _quill.updateSelection(sel, ChangeSource.local);
    _format(build(res.value));
    _bar?.markNeedsBuild();
  }

  Future<void> _pickSize() async {
    final sel = _quill.selection;
    final cur = _quill.getSelectionStyle().attributes['size']?.value;
    final res = await showRichSizePicker(context, cur is String ? cur : null);
    _apply(sel, res, (v) => SizeAttribute(v));
  }

  Future<void> _pickFont() async {
    final sel = _quill.selection;
    final cur = _quill.getSelectionStyle().attributes['font']?.value;
    final res = await showRichFontPicker(context, cur is String ? cur : null);
    _apply(sel, res, (v) => FontAttribute(v));
  }

  Future<void> _pickColor() async {
    final sel = _quill.selection;
    final cur = _quill.getSelectionStyle().attributes['color']?.value;
    final res = await showRichColorPicker(context,
        palette: kRichInkChart,
        current: cur is String ? cur : null,
        title: '글자색',
        clearLabel: '기본색으로');
    _apply(
        sel,
        res,
        (v) => v == null
            ? Attribute.clone(ColorAttribute(''), null)
            : ColorAttribute(v));
  }

  Future<void> _pickHighlight() async {
    final sel = _quill.selection;
    final cur = _quill.getSelectionStyle().attributes['background']?.value;
    final res = await showRichColorPicker(context,
        palette: kRichHighlightChart,
        current: cur is String ? cur : null,
        title: '형광펜',
        clearLabel: '형광펜 지우기');
    _apply(
        sel,
        res,
        (v) => v == null
            ? Attribute.clone(BackgroundAttribute(''), null)
            : BackgroundAttribute(v));
  }

  bool _active(String key) => _quill.getSelectionStyle().attributes.containsKey(key);

  DefaultStyles _styles(BuildContext context) {
    final base = DefaultStyles.getInstance(context);
    final fs = widget.fontSize;
    final para = base.paragraph ??
        DefaultTextBlockStyle(const TextStyle(), HorizontalSpacing.zero,
            VerticalSpacing.zero, VerticalSpacing.zero, null);
    return base.merge(DefaultStyles(
      paragraph: para.copyWith(
        style: TextStyle(
          fontFamily: coverFontFamily(widget.fontId),
          fontSize: fs,
          height: 1.35,
          color: widget.baseColor,
        ),
        verticalSpacing: VerticalSpacing.zero,
        lineSpacing: VerticalSpacing.zero,
      ),
      sizeSmall: TextStyle(fontSize: fs * kRichSizeMultipliers['small']!),
      sizeLarge: TextStyle(fontSize: fs * kRichSizeMultipliers['large']!),
      sizeHuge: TextStyle(fontSize: fs * kRichSizeMultipliers['huge']!),
      placeHolder: para.copyWith(
        style: TextStyle(
          fontSize: fs,
          height: 1.35,
          color: AppColors.textHint,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: QuillEditor(
        focusNode: _focus,
        scrollController: _scroll,
        controller: _quill,
        config: QuillEditorConfig(
          scrollable: true,
          autoFocus: true,
          expands: true,
          padding: EdgeInsets.all(widget.fontSize * 0.35),
          placeholder: '여기에 입력',
          customStyles: _styles(context),
        ),
      ),
    );
  }

  // 최상위 Overlay의 화면 하단(키보드 바로 위)에 가로 전체로 깔리는 편집바.
  // [ctx]는 rootOverlay 컨텍스트라 Scaffold가 삼키지 않은 실제 키보드 높이를 준다.
  Widget _barOverlay(BuildContext ctx) {
    final kb = MediaQuery.of(ctx).viewInsets.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: kb, // 키보드가 열리면 그 바로 위, 닫히면 화면 맨 아래
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Center(child: _toolbar()),
        ),
      ),
    );
  }

  Widget _toolbar() {
    final curColor = () {
      final v = _quill.getSelectionStyle().attributes['color']?.value;
      return richParseColor(v) ?? AppColors.textPrimary;
    }();
    final curHi = () {
      final v = _quill.getSelectionStyle().attributes['background']?.value;
      return richParseColor(v);
    }();
    // TextFieldTapRegion: 이 영역 탭은 "텍스트필드 안"으로 취급돼 에디터가
    // 포커스를 잃지 않는다(버튼 눌러도 선택·키보드 유지, 편집바도 안 사라짐).
    return TextFieldTapRegion(
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
            children: [
              _btn(Icons.format_bold, () => _toggle(Attribute.bold),
                  active: _active('bold')),
              _btn(Icons.format_italic, () => _toggle(Attribute.italic),
                  active: _active('italic')),
              _btn(Icons.format_underlined, () => _toggle(Attribute.underline),
                  active: _active('underline')),
              _btn(Icons.strikethrough_s, () => _toggle(Attribute.strikeThrough),
                  active: _active('strike')),
              const SizedBox(width: 2),
              _btn(Icons.format_size, _pickSize, active: _active('size')),
              _btn(Icons.font_download, _pickFont, active: _active('font')),
              _btn(Icons.format_color_text, _pickColor,
                  active: _active('color'), tint: curColor),
              _btn(Icons.border_color, _pickHighlight,
                  active: _active('background'), tint: curHi),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap,
      {bool active = false, Color? tint}) {
    return InkWell(
      onTap: () {
        onTap();
        _bar?.markNeedsBuild(); // 활성 상태 표시 갱신(Overlay 재빌드)
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: tint ?? (active ? AppColors.primary : AppColors.textPrimary)),
      ),
    );
  }
}
