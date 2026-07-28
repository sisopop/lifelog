// 일기 **본문** 리치텍스트 인라인 편집기 + 선택 서식 툴바(flutter_quill 기반).
//
// 텍스트박스(textbox_rich_editor.dart)와 같은 방식이다. 본문 글을 드래그해 범위를
// 선택하면 키보드 바로 위에 작은 편집바가 떠 굵게/기울임/밑줄/취소선/크기/글꼴/색/
// 형광펜을 그 범위에만 적용한다. 저장은 Quill Delta JSON(DiaryEntry.contentRich) +
// 검색·통계·AI용 평문(content). 읽기 렌더는 textbox_rich.dart(richTextSpan)가 공용.
//
// [controller]는 글쓰기 화면(_WriteScreenState)이 소유한다(프리필·저장·이모지/프롬프트
// 삽입에 함께 쓰이므로). 이 위젯은 controller를 dispose하지 않고 포커스·편집바만 관리한다.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/keyboard_edit.dart';
import '../decorate/rich_format_pickers.dart';
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

// 편집바(키보드 위 서식바)가 가리는 높이. 커서를 "자판 위 남은 공간"의 가운데에
// 둘 때 이 높이를 빼고 계산한다.
const double kBodyFormatBarHeight = 56.0;

// 타자기식(typewriter) 스크롤 목표치. 커서([caretY], 화면 좌표)를 스크롤 뷰포트
// (상단 [viewportTop], 높이 [viewportHeight])에서 편집바([barHeight])를 뺀 영역의
// **가운데**에 두려면 스크롤 위치를 얼마로 해야 하는지 돌려준다.
//
// 현재 위치([pixels])와 2px 미만 차이면(=이미 가운데) null을 돌려 불필요한 스크롤을
// 막는다. 결과는 [minExtent]~[maxExtent]로 클램프되므로 문서 처음·끝에서는
// 가운데보다 덜 움직인다.
double? typewriterScrollTarget({
  required double caretY,
  required double viewportTop,
  required double viewportHeight,
  required double barHeight,
  required double pixels,
  required double minExtent,
  required double maxExtent,
}) {
  final wantY = viewportTop + (viewportHeight - barHeight) / 2;
  final target = (pixels + (caretY - wantY)).clamp(minExtent, maxExtent);
  if ((target - pixels).abs() < 2) return null;
  return target;
}

class _BodyRichEditorState extends State<BodyRichEditor>
    with WidgetsBindingObserver {
  final _focus = FocusNode();
  final _scroll = ScrollController();
  // 커서 위치(캐럿 사각형)를 물어보기 위한 flutter_quill 내부 에디터 키.
  final GlobalKey<EditorState> _editorKey = GlobalKey<EditorState>();

  // 편집바는 최상위 Overlay의 화면 하단(키보드 바로 위) 고정 위치에 띄운다.
  OverlayEntry? _bar;

  QuillController get _quill => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focus.addListener(_onFocusChange);
    _quill.addListener(_onChanged);
  }

  // 커서/선택/내용이 바뀌면 서식 버튼 상태를 갱신하고, 편집 중이면 커서를 다시
  // 가운데로 맞춘다(줄이 늘면 윗줄이 위로 밀려 올라가고 커서는 계속 가운데).
  void _onChanged() {
    _bar?.markNeedsBuild();
    _centerCaret();
  }

  // 포커스가 바뀌면 편집바를 동기화하고 build를 다시 돌린다(편집 레이아웃 전환).
  void _onFocusChange() {
    _syncBar();
    _centerCaret();
    if (mounted) setState(() {});
  }

  // 자판이 오르내리는 동안 아래 여백을 다시 계산하고(자판 위 공간에 맞춤),
  // 커서를 다시 가운데로 맞춘다.
  @override
  void didChangeMetrics() {
    if (mounted && _focus.hasFocus) setState(() {});
    _syncBar();
    _centerCaret();
  }

  // 자판 실제 높이(논리 px). Scaffold(resizeToAvoidBottomInset)가 body의
  // MediaQuery.viewInsets를 이미 소비해 0으로 보이므로 FlutterView에서 직접 읽는다.
  double get _kb =>
      MediaQueryData.fromView(View.of(context)).viewInsets.bottom;

  // "편집 중"은 포커스가 있고 **자판이 실제로 떠 있을 때**만이다. (안드로이드
  // 뒤로가기는 포커스를 그대로 두고 자판만 내리므로 포커스만으로는 판단 못 한다.)
  // 단, 웹은 자판 높이를 보고하지 않아(항상 0) 포커스만 본다 → isKeyboardEditing.
  bool get _editing => isKeyboardEditing(
        hasFocus: _focus.hasFocus,
        keyboardHeight: _kb,
        isWeb: kIsWeb,
      );

  // 편집 중(포커스+자판 위)이면 **바깥 리스트**를 스크롤해 커서를 자판 위 남은
  // 공간(뷰포트에서 편집바 높이를 뺀 영역)의 가운데에 둔다.
  //
  // 에디터 자체는 scrollable:false로 내용만큼 자라므로, 스크롤은 전부 바깥
  // ListView가 담당한다(중첩 스크롤 회피). flutter_quill의 내부 커서 자동
  // 스크롤은 이 배치에서 동작하지 않아 직접 계산한다.
  void _centerCaret() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_editing) return;
      final ro = _editorKey.currentState?.renderEditor;
      final sp = Scrollable.maybeOf(context);
      if (ro == null || sp == null || !ro.attached || !ro.hasSize) return;
      final vp = sp.context.findRenderObject();
      if (vp is! RenderBox || !vp.hasSize) return;
      final pos = _quill.selection.extentOffset
          .clamp(0, _quill.document.length - 1)
          .toInt();
      final Rect caret;
      try {
        caret = ro.getLocalRectForCaret(TextPosition(offset: pos));
      } catch (_) {
        return;
      }
      final target = typewriterScrollTarget(
        caretY: ro.localToGlobal(caret.center).dy,
        viewportTop: vp.localToGlobal(Offset.zero).dy,
        viewportHeight: vp.size.height,
        barHeight: kBodyFormatBarHeight,
        pixels: sp.position.pixels,
        minExtent: sp.position.minScrollExtent,
        maxExtent: sp.position.maxScrollExtent,
      );
      // 애니메이션 없이 즉시 맞춘다(자판 애니메이션·연속 타이핑과 충돌 방지).
      if (target != null) sp.position.jumpTo(target);
    });
  }

  // 편집바는 자판이 떠 있을 때만 띄운다(자판을 내리면 원래 글쓰기 화면으로 복귀).
  void _syncBar() {
    if (!mounted) return;
    final show = _editing;
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
    WidgetsBinding.instance.removeObserver(this);
    _focus.removeListener(_onFocusChange);
    _quill.removeListener(_onChanged);
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // 선택 범위에 [attr]이 이미 있으면 지우고, 없으면 적용한다(토글).
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
  // 포커스를 잃으므로, 열기 전 선택 범위([sel])를 복원한 뒤 서식을 적용한다.
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
    final mq = MediaQueryData.fromView(View.of(context));
    final kb = mq.viewInsets.bottom;
    final editing = isKeyboardEditing(
      hasFocus: _focus.hasFocus,
      keyboardHeight: kb,
      isWeb: kIsWeb,
    );
    // 에디터는 항상 scrollable:false로 **내용만큼 자란다**(중첩 스크롤 금지).
    // 스크롤·커서 가운데 맞추기는 바깥 ListView가 담당한다(_centerCaret).
    //
    // 편집 중에는 에디터 아래에 여백(스페이서)을 하나 둔다. 문서 끝 줄에서도
    // 아래로 더 스크롤할 여지가 있어야 커서를 가운데까지 끌어올릴 수 있기 때문이다.
    // 자판을 내리면 여백이 사라져 원래 글쓰기 화면으로 복귀한다.
    final gap = editing ? (mq.size.height - kb) * 0.45 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
              editorKey: _editorKey,
              scrollable: false,
              expands: false,
              autoFocus: false,
              placeholder: '오늘 어떤 하루였나요?',
              customStyles: _styles(context),
            ),
          ),
        ),
        SizedBox(height: gap),
      ],
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
