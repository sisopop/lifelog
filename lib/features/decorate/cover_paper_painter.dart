import 'package:flutter/material.dart';

import 'cover_paper.dart';
import 'cover_paper_color.dart';

/// 속지(내지) 종이 무늬를 그리는 CustomPainter.
///
/// - lined : 가로줄만(여백선 없음)
/// - ruled : 가로줄 + 왼쪽 세로 여백선 하나(줄노트)
/// - grid  : 가로·세로 모눈
/// - dot   : 일정 간격 도트
/// - plain : 아무것도 그리지 않음(무지)
///
/// 선은 매우 옅게 그려 글자 가독성을 해치지 않는다.
class PaperPainter extends CustomPainter {
  PaperPainter(this.paper, {this.spacing = 28, this.lineColor});

  final String paper;

  /// 줄 간격(작은 미리보기는 더 작게).
  final double spacing;

  /// 가로/모눈/도트 선 색. null이면 옅은 검정.
  final Color? lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final id = normalizeCoverPaper(paper);
    if (id == kDefaultCoverPaper) return;

    final line = Paint()
      ..color = lineColor ?? const Color(0x14000000)
      ..strokeWidth = 1
      ..isAntiAlias = true;

    switch (id) {
      case 'lined':
        // 가로줄만 — 여백선 없는 깔끔한 줄노트.
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        break;
      case 'ruled':
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        // 왼쪽 세로 여백선 하나(붉은 기 도는 옅은 선).
        final margin = Paint()
          ..color = const Color(0x33D08A8A)
          ..strokeWidth = 1.2
          ..isAntiAlias = true;
        final mx = (size.width * 0.12).clamp(8.0, 32.0);
        canvas.drawLine(Offset(mx, 0), Offset(mx, size.height), margin);
        break;
      case 'grid':
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (double x = spacing; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
        break;
      case 'dot':
        final dot = Paint()..color = lineColor ?? const Color(0x1F000000);
        final r = (spacing * 0.045).clamp(0.8, 1.4);
        for (double y = spacing; y < size.height; y += spacing) {
          for (double x = spacing; x < size.width; x += spacing) {
            canvas.drawCircle(Offset(x, y), r, dot);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant PaperPainter old) =>
      old.paper != paper ||
      old.spacing != spacing ||
      old.lineColor != lineColor;
}

/// 자식 위젯 뒤에 속지 무늬·바탕색을 깔아주는 배경 위젯.
/// 무지+크림(둘 다 기본)이면 그대로 보여 기존 화면과 동일하다.
class PaperBackground extends StatelessWidget {
  const PaperBackground({
    super.key,
    required this.paper,
    this.paperColor = kDefaultPaperColor,
    required this.child,
    this.spacing = 30,
  });

  final String paper;

  /// 종이 바탕색 id('cream' = 기본). See cover_paper_color.dart.
  final String paperColor;
  final double spacing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final normPaper = normalizeCoverPaper(paper);
    final normColor = normalizePaperColor(paperColor);
    // 둘 다 기본이면 배경을 입히지 않고 원래 화면 그대로 둔다.
    if (normPaper == kDefaultCoverPaper && normColor == kDefaultPaperColor) {
      return child;
    }
    // 무지면 바탕색만, 무늬가 있으면 그 위에 줄/모눈/도트를 그린다.
    if (normPaper == kDefaultCoverPaper) {
      return DecoratedBox(
        decoration: BoxDecoration(color: paperColorOf(normColor)),
        child: child,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: paperColorOf(normColor)),
      child: CustomPaint(
        painter: PaperPainter(paper, spacing: spacing),
        child: child,
      ),
    );
  }
}
