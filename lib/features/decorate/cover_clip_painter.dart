import 'package:flutter/material.dart';

import 'cover_clip.dart';

/// 표지 윗변에 꽂힌 페이퍼클립을 절차적으로 그리는 페인터.
/// 'none'은 아무것도 그리지 않습니다. 클립은 윗변 가운데-오른쪽(x0.64,
/// 좌상단 아이콘/가운데 리본/우측 밴드·우상단 배지와 겹치지 않게)에서
/// 윗변 위로 살짝 솟아 꽂혀 있습니다. 크기는 표지 크기에 비례합니다.
/// 중첩된 두 개의 둥근 알약(pill) 윤곽으로 클립 실루엣을 만듭니다.
class CoverClipPainter extends CustomPainter {
  const CoverClipPainter(this.clip, {this.scale = 1.0});

  /// cover_clip.dart의 클립 id.
  final String clip;

  /// 작은 미리보기/큰 책장에서 클립 크기를 맞추기 위한 배율.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final id = normalizeCoverClip(clip);
    final argb = coverClipColors[id];
    if (argb == null) return; // none.
    final color = Color(argb);

    // 윗변 가운데-오른쪽에 세로로 길쭉한 클립. 길이를 표지 높이에 비례시켜
    // 작은 칩에서도 큰 책장에서도 '클립'으로 또렷이 읽히게 한다.
    final cx = size.width * 0.64;
    final w = size.width * 0.15; // 표지 폭에 비례한 클립 폭.
    final topY = -size.height * 0.12; // 윗변 위로 또렷이 솟아(끼운 느낌).
    final botY = size.height * 0.2; // 윗변을 무는 짧은 몸체.
    final stroke = (size.width * 0.028).clamp(2.4, 6.0);
    final r = Radius.circular(w / 2);

    final wire = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final hi = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.42
      ..strokeCap = StrokeCap.round;

    final outer = RRect.fromLTRBR(cx - w / 2, topY, cx + w / 2, botY, r);
    final inset = w * 0.32;
    final inner = RRect.fromLTRBR(
        cx - w / 2 + inset,
        topY + w * 0.55,
        cx + w / 2 - inset,
        botY - w * 0.7,
        Radius.circular((w - 2 * inset) / 2));

    canvas.drawRRect(
        outer.shift(Offset(stroke * 0.4, stroke * 0.6)), shadow);
    canvas.drawRRect(outer, wire);
    canvas.drawRRect(inner, wire);
    // 왼쪽 가장자리 금속 하이라이트.
    canvas.drawLine(
      Offset(cx - w / 2 + stroke * 0.3, topY + w),
      Offset(cx - w / 2 + stroke * 0.3, botY - w),
      hi,
    );
  }

  @override
  bool shouldRepaint(CoverClipPainter old) =>
      old.clip != clip || old.scale != scale;
}
