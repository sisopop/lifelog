// 텍스트박스 **리치텍스트 인라인 편집기** + 선택 서식 툴바(flutter_quill 기반).
//
// 선택된 텍스트박스 안에서 바로 글을 쓰고, 글을 드래그해 범위 선택하면 상자 위에
// 작은 편집바가 떠서 굵게/기울임/밑줄/취소선/글자색/형광펜/글꼴/크기를 그 범위에만
// 적용한다. 저장은 Quill Delta JSON([DecoLayer.richValue]) + 검색·통계용 평문([value]).
// 읽기 전용 렌더는 textbox_rich.dart(richTextSpan)가 담당한다.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/theme/app_colors.dart';
import 'cover_font.dart';
import 'text_color_catalog.dart';
import 'text_highlight_catalog.dart';
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

class _TextBoxRichEditorState extends State<TextBoxRichEditor> {
  late final QuillController _quill;
  final _focus = FocusNode();
  final _scroll = ScrollController();
  String _lastPlain = '';
  String _lastJson = '';
  bool _hasSelection = false;

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
  }

  void _onQuillChanged() {
    final sel = !_quill.selection.isCollapsed;
    if (sel != _hasSelection && mounted) {
      setState(() => _hasSelection = sel);
    }
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
    _quill.removeListener(_onQuillChanged);
    _quill.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // 선택 범위에 [attr]이 이미 있으면 지우고(같은 값이면), 없으면 적용한다(토글).
  void _toggle(Attribute attr) {
    final cur = _quill.getSelectionStyle().attributes;
    if (cur.containsKey(attr.key)) {
      _quill.formatSelection(Attribute.clone(attr, null));
    } else {
      _quill.formatSelection(attr);
    }
  }

  void _cycleSize() {
    final cur = _quill.getSelectionStyle().attributes['size']?.value;
    final i = kRichSizeCycle.indexOf(cur is String ? cur : null);
    final next = kRichSizeCycle[(i < 0 ? 0 : i + 1) % kRichSizeCycle.length];
    _quill.formatSelection(SizeAttribute(next));
  }

  void _cycleFont() {
    final cur = _quill.getSelectionStyle().attributes['font']?.value;
    // 팔레트 순서로 순환. 현재 family 문자열로 인덱스를 찾고 다음으로.
    var i = coverFontPalette.indexWhere((f) => f.family == cur);
    if (i < 0) i = 0;
    final next = coverFontPalette[(i + 1) % coverFontPalette.length];
    _quill.formatSelection(
        FontAttribute(next.family)); // null이면 기본 글꼴로 되돌림
  }

  void _cycleColor() {
    final cur = _quill.getSelectionStyle().attributes['color']?.value;
    final curHex = cur is String ? cur.toLowerCase() : null;
    var i = kTextInkColors
        .indexWhere((c) => richColorHex(c).toLowerCase() == curHex);
    // 없으면(=기본색) 첫 색부터, 있으면 다음. 마지막 다음은 기본색(제거).
    final nextIdx = curHex == null ? 0 : i + 1;
    if (nextIdx >= kTextInkColors.length) {
      _quill.formatSelection(Attribute.clone(ColorAttribute(''), null));
    } else {
      _quill.formatSelection(ColorAttribute(richColorHex(kTextInkColors[nextIdx])));
    }
  }

  void _cycleHighlight() {
    final cur = _quill.getSelectionStyle().attributes['background']?.value;
    final curHex = cur is String ? cur.toLowerCase() : null;
    var i = kTextHighlightColors
        .indexWhere((c) => richColorHex(c).toLowerCase() == curHex);
    final nextIdx = curHex == null ? 0 : i + 1;
    if (nextIdx >= kTextHighlightColors.length) {
      _quill.formatSelection(Attribute.clone(BackgroundAttribute(''), null));
    } else {
      _quill.formatSelection(
          BackgroundAttribute(richColorHex(kTextHighlightColors[nextIdx])));
    }
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
    final editor = SizedBox(
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
    // 편집바는 상자 위에 떠 있고(선택이 있을 때만), 클립을 벗어나도 보이게 Stack
    // clipBehavior none. 상자가 화면 맨 위면 살짝 가려질 수 있으나 대개 문제없다.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        editor,
        if (_hasSelection)
          Positioned(
            left: -widget.width * 0.05,
            bottom: widget.height + 6,
            child: _toolbar(),
          ),
      ],
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
    return Material(
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
              _btn(Icons.format_size, _cycleSize, active: _active('size')),
              _btn(Icons.font_download, _cycleFont, active: _active('font')),
              _btn(Icons.format_color_text, _cycleColor,
                  active: _active('color'), tint: curColor),
              _btn(Icons.border_color, _cycleHighlight,
                  active: _active('background'), tint: curHi),
            ],
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
        setState(() {}); // 활성 상태 표시 갱신
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
