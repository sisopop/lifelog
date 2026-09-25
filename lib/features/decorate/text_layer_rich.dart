// "글자 넣기"(text 레이어) **리치텍스트** 공용 순수 로직.
//
// 텍스트박스와 같은 저장 형식(Quill Delta JSON → DecoLayer.richValue)을 쓴다. 옛
// 글자 레이어는 굵게/기울임/밑줄/취소선/형광펜을 **레이어 전체 플래그**로 저장했으므로,
// 편집 다이얼로그를 열 때 그 플래그를 "글 전체에 걸린 서식"인 Delta로 바꿔 시드한다
// (저장하면 플래그 대신 Delta가 서식을 담는다 → 눈에 보이는 모양은 그대로).
// flutter_quill에 의존하지 않아 단위 테스트가 쉽다.

import 'dart:convert';

import 'package:flutter/material.dart';

import 'textbox_rich.dart';

/// 옛 레이어 전체 플래그를 글 전체에 걸린 서식의 Delta JSON으로 바꾼다. 켜진 플래그가
/// 하나도 없으면(=평범한 글) null — 평문으로 시작하면 된다. [text]가 비면 null.
String? seedTextLayerRich({
  required String text,
  bool bold = false,
  bool italic = false,
  bool underline = false,
  bool strike = false,
  int? bgColorValue,
}) {
  if (text.isEmpty) return null;
  final attrs = <String, dynamic>{
    if (bold) 'bold': true,
    if (italic) 'italic': true,
    if (underline) 'underline': true,
    if (strike) 'strike': true,
    if (bgColorValue != null) 'background': richColorHex(Color(bgColorValue)),
  };
  if (attrs.isEmpty) return null;
  return jsonEncode([
    {'insert': text, 'attributes': attrs},
    {'insert': '\n'},
  ]);
}

/// Delta JSON에 서식(attributes)이 하나라도 있는지. 없으면 저장할 때 richValue를
/// null로 둬서 평범한 글 레이어는 예전과 똑같이(평문 경로로) 저장·렌더되게 한다.
/// 깨진 JSON·null은 false.
bool richHasFormatting(String? richJson) {
  if (richJson == null || richJson.trim().isEmpty) return false;
  try {
    final ops = jsonDecode(richJson);
    if (ops is! List) return false;
    for (final op in ops) {
      if (op is Map && op['attributes'] is Map && (op['attributes'] as Map).isNotEmpty) {
        return true;
      }
    }
    return false;
  } catch (_) {
    return false;
  }
}
