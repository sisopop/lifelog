// 텍스트박스(직접 입력 상자) **리치텍스트** 공용 순수 로직 + 읽기 전용 렌더.
//
// 편집기(flutter_quill)와 읽기 화면(상세·카드·미리보기)이 같은 규칙으로 서식을
// 재현하도록, 저장은 Quill Delta JSON(DecoLayer.richValue) 하나로 통일한다. 이
// 파일은 flutter_quill에 의존하지 않는다(읽기 렌더는 순수 Flutter TextSpan). 편집
// 위젯·툴바는 textbox_rich_editor.dart가 담당한다.

import 'dart:convert';

import 'package:flutter/material.dart';

import 'cover_font.dart';

/// 리치텍스트에서 쓰는 **상대 글자 크기** 토큰('size' 속성 값) → 기본 글자크기 대비
/// 배율. flutter_quill의 sizeSmall/Large/Huge와 같은 키를 쓴다. 키가 없으면(=normal)
/// 1.0. 편집기(QuillEditor DefaultStyles)와 읽기 렌더가 **같은 배율**을 써야 화면
/// 크기가 달라도(편집/상세/카드) 글자 크기가 같은 비율로 보인다(WYSIWYG).
const Map<String, double> kRichSizeMultipliers = {
  'small': 0.75,
  'large': 1.4,
  'huge': 1.8,
};

/// 크기 순환 토글에 쓰는 순서(기본 → 크게 → 아주크게 → 작게 → …). null=기본(normal).
const List<String?> kRichSizeCycle = [null, 'large', 'huge', 'small'];

double richSizeMultiplier(Object? sizeValue) {
  if (sizeValue == null) return 1.0;
  return kRichSizeMultipliers[sizeValue.toString()] ?? 1.0;
}

/// Quill 색 문자열('#RRGGBB' 또는 '#AARRGGBB')을 [Color]로. 형식이 아니면 null.
Color? richParseColor(Object? v) {
  if (v is! String || !v.startsWith('#')) return null;
  var hex = v.substring(1);
  if (hex.length == 6) hex = 'ff$hex';
  final n = int.tryParse(hex, radix: 16);
  return n == null ? null : Color(n);
}

/// [Color] → Quill 저장용 '#RRGGBB'(불투명 가정, 알파 버림).
String richColorHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// 텍스트박스의 리치텍스트(Quill Delta JSON [richValue])를 **읽기용** [InlineSpan]으로
/// 바꾼다. richValue가 없거나 깨졌으면 평문 [plainFallback]을 기본 스타일로 그린다.
/// [baseFontSize]는 이 렌더 자리(편집/상세/카드)의 기본 글자 크기라, 화면마다 달라도
/// 상대 크기·서식은 동일하게 재현된다. [fontId]·[baseColor]는 상자 기본 글꼴·색.
InlineSpan richTextSpan({
  required String? richValue,
  required String plainFallback,
  required double baseFontSize,
  required String fontId,
  required Color baseColor,
}) {
  final base = TextStyle(
    fontFamily: coverFontFamily(fontId),
    fontSize: baseFontSize,
    height: 1.35,
    color: baseColor,
  );
  if (richValue == null || richValue.trim().isEmpty) {
    return TextSpan(text: plainFallback, style: base);
  }
  try {
    final ops = jsonDecode(richValue);
    if (ops is! List) return TextSpan(text: plainFallback, style: base);
    final spans = <InlineSpan>[];
    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert is! String) continue; // 임베드(사진 등)는 텍스트박스에 없음 → 건너뜀
      final attrs = op['attributes'];
      spans.add(TextSpan(
        text: insert,
        style: _styleFromAttrs(base, baseFontSize,
            attrs is Map ? attrs.cast<String, dynamic>() : const {}),
      ));
    }
    if (spans.isEmpty) return TextSpan(text: plainFallback, style: base);
    return TextSpan(children: spans, style: base);
  } catch (_) {
    return TextSpan(text: plainFallback, style: base);
  }
}

TextStyle _styleFromAttrs(
    TextStyle base, double baseFontSize, Map<String, dynamic> a) {
  var s = base;
  if (a['bold'] == true) s = s.copyWith(fontWeight: FontWeight.w700);
  if (a['italic'] == true) s = s.copyWith(fontStyle: FontStyle.italic);
  final decos = <TextDecoration>[
    if (a['underline'] == true) TextDecoration.underline,
    if (a['strike'] == true) TextDecoration.lineThrough,
  ];
  if (decos.isNotEmpty) {
    s = s.copyWith(decoration: TextDecoration.combine(decos));
  }
  final color = richParseColor(a['color']);
  if (color != null) s = s.copyWith(color: color);
  final bg = richParseColor(a['background']);
  if (bg != null) s = s.copyWith(backgroundColor: bg);
  final font = a['font'];
  if (font is String && font.isNotEmpty) s = s.copyWith(fontFamily: font);
  final mul = richSizeMultiplier(a['size']);
  if (mul != 1.0) s = s.copyWith(fontSize: baseFontSize * mul);
  return s;
}
