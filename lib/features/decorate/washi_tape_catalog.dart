// 페이지 꾸미기용 마스킹테이프(워시테이프) 색 카탈로그.
//
// 스티커(sticker_catalog)가 이모지 조각이라면, 여기 테이프는 반투명 색 띠다.
// 사진·글 위에 살짝 겹쳐 붙여도 밑이 비쳐 보이도록 알파를 낮춰 뒀다(≈0.55).
// 순수 데이터라 단위 테스트로 검증한다. 색 매핑([washiTapeColor])은 렌더 뷰와
// 편집기가 공유한다(저장에는 스타일 id만 남고, 색은 여기서 정해진다).

import 'package:flutter/material.dart';

/// 고를 수 있는 테이프 한 종류. [id]는 저장용 키(색이 바뀌어도 기록은 안 깨짐),
/// [label]은 팔레트 표시용, [color]은 반투명 테이프 색.
class WashiTape {
  const WashiTape(this.id, this.label, this.color);
  final String id;
  final String label;
  final Color color;
}

/// 선택 가능한 테이프 카탈로그(파스텔 반투명). 첫 항목이 기본값.
const List<WashiTape> kWashiTapes = [
  WashiTape('pink', '핑크', Color(0x8CF7A8C4)),
  WashiTape('yellow', '옐로', Color(0x8CFCE38A)),
  WashiTape('mint', '민트', Color(0x8CA8E6CF)),
  WashiTape('blue', '블루', Color(0x8CA8C8F7)),
  WashiTape('lavender', '라벤더', Color(0x8CC9B8F7)),
  WashiTape('peach', '피치', Color(0x8CFBC4A0)),
];

/// 스타일 id에 해당하는 테이프 색. 알 수 없는 id는 첫 색으로 폴백해(저장본 깨짐
/// 방지) 절대 예외를 던지지 않는다.
Color washiTapeColor(String id) => kWashiTapes
    .firstWhere((t) => t.id == id, orElse: () => kWashiTapes.first)
    .color;
