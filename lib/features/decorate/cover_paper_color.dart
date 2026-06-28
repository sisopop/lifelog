import 'package:flutter/material.dart';

/// 속지(내지) 종이 바탕색. 읽기 화면 배경색으로 쓰인다.
/// id는 임의 문자열 저장 + normalizePaperColor 폴백이라 마이그레이션이 단순하다.
const String kDefaultPaperColor = 'cream';

class PaperColor {
  const PaperColor(this.id, this.label, this.color);
  final String id;
  final String label;
  final Color color;
}

/// 선택 가능한 종이색. 첫 항목은 항상 기본(크림).
/// 글자 가독성을 위해 모두 아주 옅은 파스텔 톤이다.
const List<PaperColor> paperColorPalette = [
  PaperColor(kDefaultPaperColor, '크림', Color(0xFFFFFDF7)),
  PaperColor('white', '화이트', Color(0xFFFFFFFF)),
  PaperColor('gray', '그레이', Color(0xFFF1F1EF)),
  PaperColor('blue', '블루', Color(0xFFEFF4FB)),
  PaperColor('pink', '핑크', Color(0xFFFBEFF4)),
  PaperColor('green', '그린', Color(0xFFEFF6F0)),
];

/// 알 수 없는 id/빈 문자열은 기본(크림)으로 폴백.
String normalizePaperColor(String id) =>
    paperColorPalette.any((p) => p.id == id) ? id : kDefaultPaperColor;

PaperColor _find(String id) => paperColorPalette.firstWhere(
      (p) => p.id == normalizePaperColor(id),
      orElse: () => paperColorPalette.first,
    );

/// id에 해당하는 종이색(없으면 크림).
Color paperColorOf(String id) => _find(id).color;

/// id에 해당하는 라벨(없으면 크림).
String paperColorLabel(String id) => _find(id).label;
