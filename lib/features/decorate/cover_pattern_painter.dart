import 'package:flutter/material.dart';

import 'cover_pattern.dart';

/// 표지 위에 절차적으로 패턴을 그리는 페인터.
/// 흰색 반투명으로 그려 어떤 표지색 위에서도 은은하게 보입니다.
class CoverPatternPainter extends CustomPainter {
  const CoverPatternPainter(this.pattern, {this.scale = 1.0});

  /// cover_pattern.dart의 패턴 id.
  final String pattern;

  /// 작은 미리보기/큰 책장에서 패턴 밀도를 맞추기 위한 배율.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final id = normalizeCoverPattern(pattern);
    if (id == kNoCoverPattern) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.16);
    final step = 18.0 * scale;

    switch (id) {
      case 'dots':
        for (double y = step; y < size.height; y += step) {
          for (double x = step; x < size.width; x += step) {
            canvas.drawCircle(Offset(x, y), 1.8 * scale, fill);
          }
        }
      case 'grid':
        for (double x = step; x < size.width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (double y = step; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case 'stripes':
        for (double y = step; y < size.height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case 'diagonal':
        final span = size.width + size.height;
        for (double d = 0; d < span; d += step) {
          canvas.drawLine(Offset(d, 0), Offset(0, d), paint);
        }
      case 'checks':
        final c = step * 1.4;
        var row = 0;
        for (double y = 0; y < size.height; y += c, row++) {
          for (double x = (row.isEven ? 0 : c); x < size.width; x += c * 2) {
            canvas.drawRect(Rect.fromLTWH(x, y, c, c), fill);
          }
        }
      case 'waves':
        for (double y = step; y < size.height; y += step) {
          final path = Path()..moveTo(0, y);
          for (double x = 0; x < size.width; x += step) {
            path.relativeQuadraticBezierTo(
                step / 2, -step / 2.2, step, 0);
          }
          canvas.drawPath(path, paint);
        }
      case 'hearts':
        for (double y = step; y < size.height; y += step * 1.4) {
          for (double x = step; x < size.width; x += step * 1.4) {
            _heart(canvas, Offset(x, y), 3.2 * scale, fill);
          }
        }
    }
  }

  void _heart(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    path.moveTo(c.dx, c.dy + r * 0.8);
    path.cubicTo(c.dx - r * 1.6, c.dy - r * 0.6, c.dx - r * 0.6,
        c.dy - r * 1.4, c.dx, c.dy - r * 0.4);
    path.cubicTo(c.dx + r * 0.6, c.dy - r * 1.4, c.dx + r * 1.6,
        c.dy - r * 0.6, c.dx, c.dy + r * 0.8);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(CoverPatternPainter old) =>
      old.pattern != pattern || old.scale != scale;
}
