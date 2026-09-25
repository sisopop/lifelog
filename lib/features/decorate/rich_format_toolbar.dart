// 리치텍스트 **인라인 서식 툴바**(자판 위 Overlay가 아니라 화면 안에 그대로 놓는 버전).
//
// "글자 넣기" 다이얼로그처럼 편집기 바로 아래에 버튼 줄을 둘 때 쓴다. 규칙은 텍스트
// 박스·글쓰기 본문 편집바와 같다: 드래그로 고른 범위가 있으면 그 부분만, 없으면(커서만)
// **글 전체**에 서식을 건다. 버튼: 굵게/기울임/밑줄/취소선/크기/글꼴/글자색/형광펜.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/theme/app_colors.dart';
import 'rich_format_pickers.dart';
import 'textbox_rich.dart';

class RichFormatToolbar extends StatefulWidget {
  const RichFormatToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final QuillController controller;

  /// 피커(바텀시트)를 닫은 뒤 포커스를 되돌릴 편집기의 FocusNode.
  final FocusNode focusNode;

  @override
  State<RichFormatToolbar> createState() => _RichFormatToolbarState();
}

class _RichFormatToolbarState extends State<RichFormatToolbar> {
  QuillController get _quill => widget.controller;

  @override
  void initState() {
    super.initState();
    _quill.addListener(_refresh);
  }

  @override
  void dispose() {
    _quill.removeListener(_refresh);
    super.dispose();
  }

  // 커서/선택이 움직이면 버튼 활성 상태·색 표시를 따라 갱신한다.
  void _refresh() {
    if (mounted) setState(() {});
  }

  void _toggle(Attribute attr) {
    final cur = _quill.getSelectionStyle().attributes;
    _format(cur.containsKey(attr.key) ? Attribute.clone(attr, null) : attr);
  }

  // 선택 범위가 있으면 그 부분만, 없으면 글 전체(마지막 개행 제외)에 적용하고,
  // 이후 입력도 그 값을 잇도록 커서 토글 스타일도 함께 건다.
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

  // 바텀시트가 뜨는 동안 편집기가 포커스를 잃으므로, 열기 전 선택([sel])을 저장했다가
  // 복원한 뒤 서식을 건다.
  void _apply(TextSelection sel, RichPick<String?>? res,
      Attribute Function(String? v) build) {
    if (res == null || !mounted) return;
    widget.focusNode.requestFocus();
    if (sel.isValid) _quill.updateSelection(sel, ChangeSource.local);
    _format(build(res.value));
  }

  Object? _cur(String key) => _quill.getSelectionStyle().attributes[key]?.value;

  Future<void> _pickSize() async {
    final sel = _quill.selection;
    final cur = _cur('size');
    final res = await showRichSizePicker(context, cur is String ? cur : null);
    _apply(sel, res, (v) => SizeAttribute(v));
  }

  Future<void> _pickFont() async {
    final sel = _quill.selection;
    final cur = _cur('font');
    final res = await showRichFontPicker(context, cur is String ? cur : null);
    _apply(sel, res, (v) => FontAttribute(v));
  }

  Future<void> _pickColor() async {
    final sel = _quill.selection;
    final cur = _cur('color');
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
    final cur = _cur('background');
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

  bool _active(String key) =>
      _quill.getSelectionStyle().attributes.containsKey(key);

  @override
  Widget build(BuildContext context) {
    final curColor = richParseColor(_cur('color')) ?? AppColors.textPrimary;
    final curHi = richParseColor(_cur('background'));
    // TextFieldTapRegion: 버튼을 눌러도 편집기 포커스·선택·자판이 유지된다.
    return TextFieldTapRegion(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _btn(Icons.format_bold, () => _toggle(Attribute.bold),
                  active: _active('bold'), tip: '굵게'),
              _btn(Icons.format_italic, () => _toggle(Attribute.italic),
                  active: _active('italic'), tip: '기울임'),
              _btn(Icons.format_underlined, () => _toggle(Attribute.underline),
                  active: _active('underline'), tip: '밑줄'),
              _btn(Icons.strikethrough_s,
                  () => _toggle(Attribute.strikeThrough),
                  active: _active('strike'), tip: '취소선'),
              _btn(Icons.format_size, _pickSize,
                  active: _active('size'), tip: '크기'),
              _btn(Icons.font_download, _pickFont,
                  active: _active('font'), tip: '글꼴'),
              _btn(Icons.format_color_text, _pickColor,
                  active: _active('color'), tint: curColor, tip: '글자색'),
              _btn(Icons.border_color, _pickHighlight,
                  active: _active('background'), tint: curHi, tip: '형광펜'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap,
      {bool active = false, Color? tint, required String tip}) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
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
              color:
                  tint ?? (active ? AppColors.primary : AppColors.textPrimary)),
        ),
      ),
    );
  }
}
