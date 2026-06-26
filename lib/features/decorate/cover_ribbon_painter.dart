import 'package:flutter/material.dart';

import 'cover_ribbon.dart';

/// 속지에 끼워진 책갈피 끈이 표지 '아래로' 삐져나온 모습을 절차적으로 그리는
/// 페인터. 표지 면 위에 그리지 않고, 표지 밑변 바로 아래에서 짧은 끈만 보이게
/// 한다(끝은 제비꼬리 notch). 'none'은 아무것도 그리지 않습니다.
/// 이 레이어는 ClipRRect 밖에서 그려지므로 표지 경계 아래로 넘어가 보인다.
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

    // 표지 밑변 왼쪽(책등 가까이)에서 끈이 내려온다 — 실제 책갈피처럼.
    // 끈은 밑변 아래로만 보이므로 좌하단 제목 텍스트와는 겹치지 않는다.
    final cx = size.width * 0.22;
    final w = (size.width * 0.1).clamp(7.0, 16.0);
    final tail = (size.height * 0.11).clamp(9.0, 18.0); // 표지 아래로 나오는 길이.
    final top = size.height - size.height * 0.015; // 밑변 살짝 위(밑에서 나오는 느낌).
    final bottom = size.height + tail;
    final notch = w * 0.5;
    final left = cx - w / 2;
    final right = cx + w / 2;

    Path body() => Path()
      ..moveTo(left, top)
      ..lineTo(right, top)
      ..lineTo(right, bottom)
      ..lineTo(cx, bottom - notch)
      ..lineTo(left, bottom)
      ..close();

    // 드롭 그림자(표지 아래 바닥에 떨어지는 느낌).
    canvas.drawPath(
      body().shift(Offset(1.2, 2.0)),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    // 끈 본체.
    canvas.drawPath(body(), Paint()..color = color);
    // 오른쪽 절반 살짝 어둡게(접힘 음영).
    canvas.drawPath(
      Path()
        ..moveTo(cx, top)
        ..lineTo(right, top)
        ..lineTo(right, bottom)
        ..lineTo(cx, bottom - notch)
        ..close(),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );
    // 왼쪽 가장자리 하이라이트.
    canvas.drawLine(
      Offset(left + 1, top),
      Offset(left + 1, bottom - notch),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(CoverRibbonPainter old) =>
      old.ribbon != ribbon || old.scale != scale;
}
