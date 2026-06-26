import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cover_corner.dart';

/// 표지 네 귀퉁이 위에 모서리 장식을 절차적으로 그리는 페인터.
/// 'none'은 아무것도 그리지 않습니다.
class CoverCornerPainter extends CustomPainter {
  const CoverCornerPainter(this.corner, {this.scale = 1.0});

  /// cover_corner.dart의 장식 id.
  final String corner;

  /// 작은 미리보기/큰 책장에서 장식 크기를 맞추기 위한 배율.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    switch (normalizeCoverCorner(corner)) {
      case 'photo':
        _photo(canvas, size);
      case 'tape':
        _tape(canvas, size);
      case 'fold':
        _fold(canvas, size);
      // none: 아무것도 그리지 않음.
    }
  }

  /// 포토 — 네 귀퉁이의 흰 삼각형 포토코너(사진첩 모서리 느낌).
  void _photo(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.16);
    final edge = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    final s = 26.0 * scale;
    final w = size.width, h = size.height;
    final corners = <Path>[
      Path()
        ..moveTo(0, 0)
        ..lineTo(s, 0)
        ..lineTo(0, s)
        ..close(),
      Path()
        ..moveTo(w, 0)
        ..lineTo(w - s, 0)
        ..lineTo(w, s)
        ..close(),
      Path()
        ..moveTo(0, h)
        ..lineTo(s, h)
        ..lineTo(0, h - s)
        ..close(),
      Path()
        ..moveTo(w, h)
        ..lineTo(w - s, h)
        ..lineTo(w, h - s)
        ..close(),
    ];
    for (final p in corners) {
      canvas.drawPath(p.shift(Offset(0.8 * scale, 0.8 * scale)), shade);
      canvas.drawPath(p, fill);
      canvas.drawPath(p, edge);
    }
  }

  /// 테이프 — 좌상·우하 귀퉁이를 45°로 가로지르는 반투명 마스킹테이프.
  void _tape(Canvas canvas, Size size) {
    final tape = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final w = size.width, h = size.height;
    final len = 42.0 * scale;
    final thick = 13.0 * scale;
    void strip(Offset center) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: len, height: thick),
          Radius.circular(2 * scale),
        ),
        tape,
      );
      canvas.restore();
    }

    strip(const Offset(0, 0));
    strip(Offset(w, h));
  }

  /// 접지 — 우상단 페이지가 살짝 접힌 도그이어(dog-ear).
  void _fold(Canvas canvas, Size size) {
    final w = size.width;
    final s = 22.0 * scale;
    final flap = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.16);
    // 접힌 자국 그림자.
    canvas.drawPath(
      Path()
        ..moveTo(w - s, 0)
        ..lineTo(w, s)
        ..lineTo(w - s, s)
        ..close(),
      shade,
    );
    // 접힌 면(흰 삼각형).
    canvas.drawPath(
      Path()
        ..moveTo(w - s, 0)
        ..lineTo(w, 0)
        ..lineTo(w, s)
        ..close(),
      flap,
    );
  }

  @override
  bool shouldRepaint(CoverCornerPainter old) =>
      old.corner != corner || old.scale != scale;
}
