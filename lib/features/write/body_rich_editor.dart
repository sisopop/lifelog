// 일기 **본문** 리치텍스트 인라인 편집기 + 선택 서식 툴바(flutter_quill 기반).
//
// 텍스트박스(textbox_rich_editor.dart)와 같은 방식이다. 본문 글을 드래그해 범위를
// 선택하면 키보드 바로 위에 작은 편집바가 떠 굵게/기울임/밑줄/취소선/크기/글꼴/색/
// 형광펜을 그 범위에만 적용한다. 저장은 Quill Delta JSON(DiaryEntry.contentRich) +
// 검색·통계·AI용 평문(content). 읽기 렌더는 textbox_rich.dart(richTextSpan)가 공용.
//
// [controller]는 글쓰기 화면(_WriteScreenState)이 소유한다(프리필·저장·이모지/프롬프트
// 삽입에 함께 쓰이므로). 이 위젯은 controller를 dispose하지 않고 포커스·편집바만 관리한다.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/theme/app_colors.dart';
import '../decorate/cover_font.dart';
import '../decorate/text_color_catalog.dart';
import '../decorate/text_highlight_catalog.dart';
import '../decorate/textbox_rich.dart';

class BodyRichEditor extends StatefulWidget {
  const BodyRichEditor({
    super.key,
    required this.controller,
    this.baseFontSize = 15,
  });

  final QuillController controller;
  final double baseFontSize;

  @override
  State<BodyRichEditor> createState() => _BodyRichEditorState();
}

class _BodyRichEditorState extends State<BodyRichEditor> {
  final _focus = FocusNode();
  final _scroll = ScrollController();

  // 편집바는 최상위 Overlay의 화면 하단(키보드 바로 위) 고정 위치에 띄운다.
  OverlayEntry? _bar;

  QuillController get _quill => widget.controller;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_syncBar);
    _quill.addListener(_onChanged);
  }

  // 커서/선택 이동에 따라 서식 버튼 활성 상태를 갱신한다.
  void _onChanged() => _bar?.markNeedsBuild();

  void _syncBar() {
    if (!mounted) return;
    final show = _focus.hasFocus;
    if (show && _bar == null) {
      _bar = OverlayEntry(builder: (ctx) => _barOverlay(ctx));
      Overlay.of(context, rootOverlay: true).insert(_bar!);
    } else if (!show && _bar != null) {
      _bar!.remove();
      _bar = null;
    }
  }

  @override
  void dispose() {
    _bar?.remove();
    _bar = null;
    _focus.removeListener(_syncBar);
    _quill.removeListener(_onChanged);
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // 선택 범위에 [attr]이 이미 있으면 지우고, 없으면 적용한다(토글).
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
    var i = coverFontPalette.indexWhere((f) => f.family == cur);
    if (i < 0) i = 0;
    final next = coverFontPalette[(i + 1) % coverFontPalette.length];
    _quill.formatSelection(FontAttribute(next.family));
  }

  void _cycleColor() {
    final cur = _quill.getSelectionStyle().attributes['color']?.value;
    final curHex = cur is String ? cur.toLowerCase() : null;
    final i = kTextInkColors
        .indexWhere((c) => richColorHex(c).toLowerCase() == curHex);
    final nextIdx = curHex == null ? 0 : i + 1;
    if (nextIdx >= kTextInkColors.length) {
      _quill.formatSelection(Attribute.clone(ColorAttribute(''), null));
    } else {
      _quill
          .formatSelection(ColorAttribute(richColorHex(kTextInkColors[nextIdx])));
    }
  }

  void _cycleHighlight() {
    final cur = _quill.getSelectionStyle().attributes['background']?.value;
    final curHex = cur is String ? cur.toLowerCase() : null;
    final i = kTextHighlightColors
        .indexWhere((c) => richColorHex(c).toLowerCase() == curHex);
    final nextIdx = curHex == null ? 0 : i + 1;
    if (nextIdx >= kTextHighlightColors.length) {
      _quill.formatSelection(Attribute.clone(BackgroundAttribute(''), null));
    } else {
      _quill.formatSelection(
          BackgroundAttribute(richColorHex(kTextHighlightColors[nextIdx])));
    }
  }

  bool _active(String key) =>
      _quill.getSelectionStyle().attributes.containsKey(key);

  DefaultStyles _styles(BuildContext context) {
    final base = DefaultStyles.getInstance(context);
    final fs = widget.baseFontSize;
    final para = base.paragraph ??
        DefaultTextBlockStyle(const TextStyle(), HorizontalSpacing.zero,
            VerticalSpacing.zero, VerticalSpacing.zero, null);
    return base.merge(DefaultStyles(
      paragraph: para.copyWith(
        style: TextStyle(
          fontSize: fs,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
      ),
      sizeSmall: TextStyle(fontSize: fs * kRichSizeMultipliers['small']!),
      sizeLarge: TextStyle(fontSize: fs * kRichSizeMultipliers['large']!),
      sizeHuge: TextStyle(fontSize: fs * kRichSizeMultipliers['huge']!),
      placeHolder: para.copyWith(
        style: TextStyle(
          fontSize: fs,
          height: 1.6,
          color: AppColors.textHint,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 바깥 ListView가 스크롤을 담당하도록 에디터는 스크롤하지 않고 내용만큼 커진다
    // (옛 TextField의 minLines:6/maxLines:null과 같은 "내용 따라 늘어남").
    return Container(
      constraints: const BoxConstraints(minHeight: 156),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: QuillEditor(
        focusNode: _focus,
        scrollController: _scroll,
        controller: _quill,
        config: QuillEditorConfig(
          scrollable: false,
          expands: false,
          autoFocus: false,
          placeholder: '오늘 어떤 하루였나요?',
          customStyles: _styles(context),
        ),
      ),
    );
  }

  Widget _barOverlay(BuildContext ctx) {
    final kb = MediaQuery.of(ctx).viewInsets.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: kb,
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
                _btn(Icons.format_underlined,
                    () => _toggle(Attribute.underline),
                    active: _active('underline')),
                _btn(Icons.strikethrough_s,
                    () => _toggle(Attribute.strikeThrough),
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
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap,
      {bool active = false, Color? tint}) {
    return InkWell(
      onTap: () {
        onTap();
        _bar?.markNeedsBuild();
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
