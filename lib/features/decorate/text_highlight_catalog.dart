// 페이지 꾸미기 글자(text) 레이어용 형광펜(배경) 색 팔레트.
//
// 글자 뒤에 깔리는 하이라이트 블록 색. null이면 배경 없음(맨 글자). 순수 데이터라
// 단위 테스트로 검증한다. 저장에는 색의 ARGB 정수(DecoLayer.bgColorValue)만 남고,
// 아래 목록은 팔레트 표시용이다. 어두운/색 글자가 위에 얹혀도 읽히도록 밝은
// 파스텔(불투명)로 고른다.

import 'package:flutter/material.dart';

/// 고를 수 있는 글자 배경(형광펜) 색(불투명). 첫 색이 팔레트 맨 앞.
const List<Color> kTextHighlightColors = [
  Color(0xFFFFF1A8), // 노랑
  Color(0xFFFFD6E0), // 핑크
  Color(0xFFCDEFD8), // 민트
  Color(0xFFCFE4FF), // 하늘
  Color(0xFFEAD9FF), // 라벤더
];
