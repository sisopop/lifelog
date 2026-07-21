import 'package:flutter/material.dart';

import 'cover_font.dart';
import 'text_color_catalog.dart';
import 'text_highlight_catalog.dart';

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
}

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

/// 문구·잉크 색·굵기를 고르는 "글자 넣기" 다이얼로그를 띄운다. 취소하거나 문구가
/// 비어 있으면 null을 돌려준다. 색 스와치와 굵게 스위치는 입력칸 미리보기에 곧바로
/// 반영된다. [initial]을 주면 그 값으로 채워 **편집 모드**로 연다(제목·버튼 라벨이
/// 바뀐다). (page_deco_playground가 500줄 상한을 넘지 않도록 분리해 둔 파일.)
Future<TextLayerInput?> showTextLayerDialog(
  BuildContext context, {
  TextLayerInput? initial,
}) async {
  final controller = TextEditingController(text: initial?.text ?? '');
  final editing = initial != null;
  var color = initial == null ? kTextInkColors.first : Color(initial.colorValue);
  var bold = initial?.bold ?? false;
  var italic = initial?.italic ?? false;
  var underline = initial?.underline ?? false;
  var strike = initial?.strike ?? false;
  var shadow = initial?.shadow ?? false;
  var fontId = normalizeCoverFont(initial?.fontId ?? kDefaultCoverFont);
  var scale = initial?.scale ?? 1.0;
  var letterSpacing = initial?.letterSpacing ?? 0.0;
  int? bg = initial?.bgColorValue; // 형광펜 배경(null=없음)
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: Text(editing ? '글자 편집' : '글자 넣기'),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 40,
              style: TextStyle(
                fontFamily: coverFontFamily(fontId),
                fontSize: 22 * scale,
                letterSpacing:
                    letterSpacing == 0.0 ? null : 22 * scale * letterSpacing * 0.06,
                color: color,
                fontWeight: bold ? FontWeight.w700 : null,
                fontStyle: italic ? FontStyle.italic : null,
                decoration: TextDecoration.combine([
                  if (underline) TextDecoration.underline,
                  if (strike) TextDecoration.lineThrough,
                ]),
                shadows: shadow
                    ? const [
                        Shadow(
                          offset: Offset(1.2, 1.2),
                          blurRadius: 1.6,
                          color: Colors.black45,
                        ),
                      ]
                    : null,
              ),
              decoration: InputDecoration(
                hintText: '예: 오늘의 한마디',
                filled: bg != null,
                fillColor: bg == null ? null : Color(bg!),
              ),
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
            Wrap(
              spacing: 10,
              children: [
                for (final c in kTextInkColors)
                  GestureDetector(
                    onTap: () => setDialog(() => color = c),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: c,
                      child: color == c
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('글꼴', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final f in coverFontPalette)
                  ChoiceChip(
                    label: Text(
                      f.label,
                      style: TextStyle(fontFamily: f.family),
                    ),
                    selected: fontId == f.id,
                    onSelected: (_) => setDialog(() => fontId = f.id),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('글자 크기', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final p in kTextSizePresets)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: nearestTextSizePreset(scale) == p.value,
                    onSelected: (_) => setDialog(() => scale = p.value),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('자간', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final p in kTextSpacingPresets)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: nearestTextSpacingPreset(letterSpacing) == p.value,
                    onSelected: (_) => setDialog(() => letterSpacing = p.value),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.format_bold, size: 20),
                const SizedBox(width: 8),
                const Text('굵게'),
                const Spacer(),
                Switch(
                  value: bold,
                  onChanged: (v) => setDialog(() => bold = v),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.format_italic, size: 20),
                const SizedBox(width: 8),
                const Text('기울임'),
                const Spacer(),
                Switch(
                  value: italic,
                  onChanged: (v) => setDialog(() => italic = v),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.format_underlined, size: 20),
                const SizedBox(width: 8),
                const Text('밑줄'),
                const Spacer(),
                Switch(
                  value: underline,
                  onChanged: (v) => setDialog(() => underline = v),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.strikethrough_s, size: 20),
                const SizedBox(width: 8),
                const Text('취소선'),
                const Spacer(),
                Switch(
                  value: strike,
                  onChanged: (v) => setDialog(() => strike = v),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.wb_shade, size: 20),
                const SizedBox(width: 8),
                const Text('그림자'),
                const Spacer(),
                Switch(
                  value: shadow,
                  onChanged: (v) => setDialog(() => shadow = v),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('형광펜', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              children: [
                // 없음(배경 안 쓰기) 옵션.
                GestureDetector(
                  onTap: () => setDialog(() => bg = null),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(
                      bg == null ? Icons.check : Icons.format_color_reset,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
                for (final c in kTextHighlightColors)
                  GestureDetector(
                    onTap: () => setDialog(() => bg = c.toARGB32()),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: c,
                      child: bg == c.toARGB32()
                          ? const Icon(Icons.check, size: 16, color: Colors.black54)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(editing ? '저장' : '추가'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return null;
  final text = controller.text.trim();
  if (text.isEmpty) return null;
  return TextLayerInput(text, color.toARGB32(), bold, bg,
      italic: italic,
      underline: underline,
      strike: strike,
      shadow: shadow,
      fontId: fontId,
      scale: scale,
      letterSpacing: letterSpacing);
}
