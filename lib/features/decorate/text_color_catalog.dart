// 페이지 꾸미기 글자(text) 레이어용 잉크 색 팔레트.
//
// 글자 레이어는 기본적으로 먹색으로 그려지지만, 여기 색 중 하나를 골라
// 알록달록하게 쓸 수 있다. 순수 데이터라 단위 테스트로 검증한다. 저장에는
// 색의 ARGB 정수(DecoLayer.colorValue)만 남고, 아래 목록은 팔레트 표시용이다.

import 'package:flutter/material.dart';

/// 고를 수 있는 글자 잉크 색(불투명). 첫 색이 기본값.
const List<Color> kTextInkColors = [
  Color(0xFF3A3A3A), // 먹
  Color(0xFF2F6FEB), // 파랑
  Color(0xFFE5484D), // 빨강
  Color(0xFF2E9E5B), // 초록
  Color(0xFF8A6D3B), // 갈색
  Color(0xFF7C4DFF), // 보라
];
