// 페이지 꾸미기 속지(배경) 색 팔레트.
//
// PageCanvas.paperColorValue(ARGB 정수, null=기본 크림)에 저장되는 속지 바탕색.
// 무늬(PaperStyle)와 별개로 종이 자체의 색을 고른다. 글자·스티커가 위에 얹혀도
// 잘 읽히도록 아주 옅은 파스텔(불투명)로만 고른다. 순수 데이터라 단위 테스트로
// 검증한다. 아래 목록은 팔레트 표시용이고, 저장에는 색 정수만 남는다.

import 'package:flutter/material.dart';

/// 기본 속지 색(크림). null(=기본)을 이 색으로 렌더한다. 팔레트의 "기본" 칩과 뷰가 공유.
const Color kPaperDefaultCream = Color(0xFFFFF8F0);

/// 고를 수 있는 속지 바탕색(불투명, 옅은 파스텔). 기본 크림은 null로 표현하므로
/// 이 목록에는 넣지 않는다.
const List<Color> kPaperColors = [
  Color(0xFFFFFFFF), // 화이트
  Color(0xFFFFF0F3), // 핑크
  Color(0xFFEFF7F0), // 민트
  Color(0xFFEEF4FB), // 하늘
  Color(0xFFF4EFFB), // 라벤더
  Color(0xFFF3E9D8), // 크라프트
];
