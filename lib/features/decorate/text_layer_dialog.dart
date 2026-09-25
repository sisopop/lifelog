import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../core/theme/app_colors.dart';
import 'cover_font.dart';
import 'rich_format_toolbar.dart';
import 'text_color_catalog.dart';
import 'text_layer_rich.dart';
import 'textbox_rich.dart';
import 'textbox_rich_editor.dart' show buildTextBoxQuillDocument;

/// "글자 넣기" 다이얼로그가 돌려주는 입력값(문구·잉크 색·굵기·기울임·형광펜 배경).
class TextLayerInput {
  const TextLayerInput(
    this.text,
    this.colorValue,
    this.bold,
    this.bgColorValue, {
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.shadow = false,
    this.fontId = kDefaultCoverFont,
    this.scale = 1.0,
    this.letterSpacing = 0.0,
    this.richValue,
  });

  /// 앞뒤 공백을 다듬은 글 내용(빈 문구면 다이얼로그가 null을 돌려주므로 항상 비지 않음).
  final String text;

  /// 고른 잉크 색(ARGB 정수).
  final int colorValue;

  /// 굵게 그릴지.
  final bool bold;

  /// 기울여(이탤릭) 그릴지.
  final bool italic;

  /// 밑줄을 그을지.
  final bool underline;

  /// 취소선을 그을지.
  final bool strike;

  /// 글자에 옅은 그림자를 드리울지.
  final bool shadow;

  /// 형광펜(배경) 색(ARGB 정수). null이면 배경 없음.
  final int? bgColorValue;

  /// 고른 글꼴 id(cover_font.dart). 기본 [kDefaultCoverFont].
  final String fontId;

  /// 글자 크기 배율(DecoLayer.scale). 기본 1.0. 프리셋: 작게 0.8·보통 1.0·크게 1.4.
  final double scale;

  /// 글자 자간(DecoLayer.letterSpacing). 기본 0.0. 프리셋: 좁게 -1.0·기본 0.0·넓게 2.0.
  final double letterSpacing;

  /// 부분 서식(Quill Delta JSON). null이면 서식 없는 평문. 서식이 있으면 굵게·기울임·
  /// 밑줄·취소선·형광펜·글자색·글꼴·크기는 여기에 담기고 위의 레이어 플래그는 쓰지 않는다
  /// ([colorValue]·[fontId]는 서식이 없는 글자의 **기본** 색·글꼴로 남는다).
  final String? richValue;
}

/// 글자 넣기 문구 최대 길이.
const int kTextLayerMaxLength = 40;

/// "글자 크기" 프리셋 3단계(라벨·배율). 드래그로 잡은 임의 배율은 편집 시 가장 가까운
/// 프리셋이 선택돼 보이지만, 프리셋을 누르기 전까지 원래 배율은 유지된다.
const List<({String label, double value})> kTextSizePresets = [
  (label: '작게', value: 0.8),
  (label: '보통', value: 1.0),
  (label: '크게', value: 1.4),
];

/// [scale]에 가장 가까운 프리셋 배율을 돌려준다(동률이면 앞선 프리셋=더 작은 값).
/// 다이얼로그에서 어느 크기 칩을 강조할지 정할 때 쓴다.
double nearestTextSizePreset(double scale) {
  var best = kTextSizePresets.first.value;
  for (final p in kTextSizePresets) {
    if ((scale - p.value).abs() < (scale - best).abs()) best = p.value;
  }
  return best;
}

/// "자간" 프리셋 3단계(라벨·간격). 드래그로 잡은 임의 자간은 편집 시 가장 가까운
/// 프리셋이 선택돼 보이지만, 프리셋을 누르기 전까지 원래 값은 유지된다.
const List<({String label, double value})> kTextSpacingPresets = [
  (label: '좁게', value: -1.0),
  (label: '기본', value: 0.0),
  (label: '넓게', value: 2.0),
];

/// [spacing]에 가장 가까운 자간 프리셋 값을 돌려준다(동률이면 앞선 프리셋=더 좁은 값).
double nearestTextSpacingPreset(double spacing) {
  var best = kTextSpacingPresets.first.value;
  for (final p in kTextSpacingPresets) {
    if ((spacing - p.value).abs() < (spacing - best).abs()) best = p.value;
  }
  return best;
}

/// "글자 넣기" 다이얼로그를 띄운다. 입력칸은 텍스트박스와 같은 리치 편집기라, 글을
/// 드래그로 고르면 그 부분만, 안 고르면 글 전체에 굵게/기울임/밑줄/취소선/크기/글꼴/
/// 글자색/형광펜을 건다(바로 아래 서식 툴바). 글자 크기·자간·그림자는 레이어 전체
/// 속성이라 따로 고른다. 취소하거나 문구가 비면 null. [initial]을 주면 **편집 모드**
/// (제목·버튼 라벨이 바뀜)로 열고, 옛 레이어의 굵게 등 플래그는 글 전체 서식으로 옮겨
/// 시드한다(모양 그대로).
Future<TextLayerInput?> showTextLayerDialog(
  BuildContext context, {
  TextLayerInput? initial,
}) {
  return showDialog<TextLayerInput>(
    context: context,
    builder: (_) => _TextLayerDialog(initial: initial),
  );
}

class _TextLayerDialog extends StatefulWidget {
  const _TextLayerDialog({this.initial});
  final TextLayerInput? initial;

  @override
  State<_TextLayerDialog> createState() => _TextLayerDialogState();
}

class _TextLayerDialogState extends State<_TextLayerDialog> {
  late final QuillController _quill;
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late final Color _baseColor;
  late final String _baseFont;
  late double _scale;
  late double _letterSpacing;
  late bool _shadow;
  String _plain = '';

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _baseColor = i == null ? kTextInkColors.first : Color(i.colorValue);
    _baseFont = normalizeCoverFont(i?.fontId ?? kDefaultCoverFont);
    _scale = i?.scale ?? 1.0;
    _letterSpacing = i?.letterSpacing ?? 0.0;
    _shadow = i?.shadow ?? false;
    final text = i?.text ?? '';
    // 서식 Delta가 있으면 그대로, 없으면 옛 레이어 전체 플래그를 글 전체 서식으로 시드.
    final seed = i?.richValue ??
        (i == null
            ? null
            : seedTextLayerRich(
                text: text,
                bold: i.bold,
                italic: i.italic,
                underline: i.underline,
                strike: i.strike,
                bgColorValue: i.bgColorValue,
              ));
    _quill = QuillController(
      document: buildTextBoxQuillDocument(seed, text),
      selection: TextSelection.collapsed(offset: text.length),
    );
    _plain = text;
    _quill.addListener(_onChanged);
  }

  void _onChanged() {
    final p = _quill.document.toPlainText().replaceAll(RegExp(r'\n$'), '');
    if (p != _plain) setState(() => _plain = p);
  }

  @override
  void dispose() {
    _quill.removeListener(_onChanged);
    _quill.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final t = _plain.trim();
    return t.isNotEmpty && t.length <= kTextLayerMaxLength;
  }

  void _submit() {
    if (!_canSubmit) return;
    final json = jsonEncode(_quill.document.toDelta().toJson());
    Navigator.of(context).pop(TextLayerInput(
      _plain.trim(),
      _baseColor.toARGB32(),
      false, // 굵게 등은 이제 Delta(richValue)가 담는다
      null,
      shadow: _shadow,
      fontId: _baseFont,
      scale: _scale,
      letterSpacing: _letterSpacing,
      richValue: richHasFormatting(json) ? json : null,
    ));
  }

  DefaultStyles _styles(BuildContext context) {
    final base = DefaultStyles.getInstance(context);
    final fs = 22 * _scale;
    final para = base.paragraph ??
        DefaultTextBlockStyle(const TextStyle(), HorizontalSpacing.zero,
            VerticalSpacing.zero, VerticalSpacing.zero, null);
    return base.merge(DefaultStyles(
      paragraph: para.copyWith(
        style: TextStyle(
          fontFamily: coverFontFamily(_baseFont),
          fontSize: fs,
          color: _baseColor,
          letterSpacing: _letterSpacing == 0.0
              ? null
              : fs * _letterSpacing * 0.06,
          shadows: _shadow
              ? const [
                  Shadow(
                    offset: Offset(1.2, 1.2),
                    blurRadius: 1.6,
                    color: Colors.black45,
                  ),
                ]
              : null,
        ),
        verticalSpacing: VerticalSpacing.zero,
        lineSpacing: VerticalSpacing.zero,
      ),
      sizeSmall: TextStyle(fontSize: fs * kRichSizeMultipliers['small']!),
      sizeLarge: TextStyle(fontSize: fs * kRichSizeMultipliers['large']!),
      sizeHuge: TextStyle(fontSize: fs * kRichSizeMultipliers['huge']!),
      placeHolder: para.copyWith(
        style: TextStyle(fontSize: fs, color: AppColors.textHint),
      ),
    ));
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(t, style: const TextStyle(fontSize: 12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final len = _plain.trim().length;
    final over = len > kTextLayerMaxLength;
    return AlertDialog(
      title: Text(_editing ? '글자 편집' : '글자 넣기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: over ? AppColors.moodHard : AppColors.divider),
              ),
              child: QuillEditor(
                focusNode: _focus,
                scrollController: _scroll,
                controller: _quill,
                config: QuillEditorConfig(
                  autoFocus: true,
                  scrollable: true,
                  expands: false,
                  minHeight: 40,
                  maxHeight: 140,
                  placeholder: '예: 오늘의 한마디',
                  customStyles: _styles(context),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('$len/$kTextLayerMaxLength',
                    style: TextStyle(
                        fontSize: 11,
                        color: over
                            ? AppColors.moodHard
                            : AppColors.textSecondary)),
              ),
            ),
            const SizedBox(height: 4),
            // 글을 드래그로 고르면 그 부분만, 안 고르면 글 전체에 서식이 걸린다.
            RichFormatToolbar(controller: _quill, focusNode: _focus),
            _label('글자 크기'),
            Wrap(
              spacing: 8,
              children: [
                for (final p in kTextSizePresets)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: nearestTextSizePreset(_scale) == p.value,
                    onSelected: (_) => setState(() => _scale = p.value),
                  ),
              ],
            ),
            _label('자간'),
            Wrap(
              spacing: 8,
              children: [
                for (final p in kTextSpacingPresets)
                  ChoiceChip(
                    label: Text(p.label),
                    selected:
                        nearestTextSpacingPreset(_letterSpacing) == p.value,
                    onSelected: (_) => setState(() => _letterSpacing = p.value),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.wb_shade, size: 20),
                const SizedBox(width: 8),
                const Text('그림자'),
                const Spacer(),
                Switch(
                  value: _shadow,
                  onChanged: (v) => setState(() => _shadow = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(_editing ? '저장' : '추가'),
        ),
      ],
    );
  }
}
