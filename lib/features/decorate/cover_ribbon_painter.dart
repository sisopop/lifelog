import 'package:flutter/material.dart';

import 'cover_ribbon.dart';

/// 표지 윗변에서 아래로 늘어진 책갈피 리본을 절차적으로 그리는 페인터.
/// 'none'은 아무것도 그리지 않습니다. 리본은 가운데(아이콘/제목/밴드와
/// 겹치지 않게)에서 내려옵니다. 끝은 제비꼬리(swallowtail)로 잘립니다.
class CoverRibbonPainter extends CustomPainter {
  const CoverRibbonPainter(this.ribbon, {this.scale = 1.0});

  /// cover_ribbon.dart의 리본 id.
  final String ribbon;

  /// 작은 미리보기/큰 책장에서 리본 폭을 맞추기 위한 배율.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final id = normalizeCoverRibbon(ribbon);
    final argb = coverRibbonColors[id];
    if (argb == null) return; // none.
    final color = Color(argb);

    final cx = size.width * 0.52;
    final w = 11.0 * scale;
    final len = size.height * 0.52;
    final notch = 7.0 * scale;
    final left = cx - w / 2;
    final right = cx + w / 2;

    Path body() => Path()
      ..moveTo(left, -1)
      ..lineTo(right, -1)
      ..lineTo(right, len)
      ..lineTo(cx, len - notch)
      ..lineTo(left, len)
      ..close();

    // 드롭 그림자.
    canvas.drawPath(
      body().shift(Offset(1.2 * scale, 1.6 * scale)),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    // 리본 본체.
    canvas.drawPath(body(), Paint()..color = color);
    // 오른쪽 절반 살짝 어둡게(접힘 음영).
    canvas.drawPath(
      Path()
        ..moveTo(cx, -1)
        ..lineTo(right, -1)
        ..lineTo(right, len)
        ..lineTo(cx, len - notch)
        ..close(),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );
    // 왼쪽 가장자리 하이라이트.
    canvas.drawLine(
      Offset(left + 1, 0),
      Offset(left + 1, len - notch * 0.3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 1.0 * scale,
    );
  }

  @override
  bool shouldRepaint(CoverRibbonPainter old) =>
      old.ribbon != ribbon || old.scale != scale;
}
