import 'package:flutter/material.dart';

import 'cover_band.dart';

/// 표지 위에 다이어리 밴드(고무밴드/버클)를 절차적으로 그리는 페인터.
/// 'none'은 아무것도 그리지 않습니다. 밴드는 오른쪽(제목/아이콘과 겹치지 않게)에
/// 세로로 지나갑니다.
class CoverBandPainter extends CustomPainter {
  const CoverBandPainter(this.band, {this.scale = 1.0});

  /// cover_band.dart의 밴드 id.
  final String band;

  /// 작은 미리보기/큰 책장에서 밴드 두께를 맞추기 위한 배율.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    switch (normalizeCoverBand(band)) {
      case 'band':
        _band(canvas, size, size.width * 0.78, 13.0 * scale);
        _buckleAt(canvas, size, size.width * 0.78, 13.0 * scale, false);
      case 'buckle':
        _band(canvas, size, size.width * 0.78, 14.0 * scale);
        _buckleAt(canvas, size, size.width * 0.78, 14.0 * scale, true);
      case 'double':
        _band(canvas, size, size.width * 0.70, 8.0 * scale);
        _band(canvas, size, size.width * 0.82, 8.0 * scale);
      // none: 아무것도 그리지 않음.
    }
  }

  /// 세로 고무밴드 — 어두운 반투명 띠 + 가장자리 하이라이트.
  void _band(Canvas canvas, Size size, double cx, double width) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.1);
    final fill = Paint()..color = Colors.black.withValues(alpha: 0.28);
    final hi = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    final rect = Rect.fromLTWH(cx - width / 2, -1, width, size.height + 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(2 * scale));
    canvas.drawRRect(rrect.shift(Offset(1.2 * scale, 0)), shadow);
    canvas.drawRRect(rrect, fill);
    canvas.drawLine(Offset(cx - width / 2 + 1, 0),
        Offset(cx - width / 2 + 1, size.height), hi);
  }

  /// 버클(금속 클립) — 밴드 가운데에 얹는 작은 사각 클립.
  void _buckleAt(
      Canvas canvas, Size size, double cx, double width, bool metal) {
    if (!metal) return;
    final cy = size.height * 0.5;
    final bw = width + 8.0 * scale;
    final bh = 14.0 * scale;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: bw, height: bh);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(3 * scale));
    canvas.drawRRect(
        rrect.shift(Offset(1.0 * scale, 1.0 * scale)),
        Paint()..color = Colors.black.withValues(alpha: 0.18));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFE6E1D8));
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * scale);
    // 가운데 핀 구멍.
    canvas.drawCircle(Offset(cx, cy), 1.6 * scale,
        Paint()..color = Colors.black.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(CoverBandPainter old) =>
      old.band != band || old.scale != scale;
}
