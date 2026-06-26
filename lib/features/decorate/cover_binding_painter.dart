import 'package:flutter/material.dart';

import 'cover_binding.dart';

/// 책등(왼쪽 가장자리) 위에 제본 장식을 절차적으로 그리는 페인터.
/// 'plain'(무선)은 아무것도 그리지 않고 기존 단색 책등 띠만 보입니다.
class CoverBindingPainter extends CustomPainter {
  const CoverBindingPainter(this.binding, {this.scale = 1.0});

  /// cover_binding.dart의 제본 id.
  final String binding;

  /// 작은 미리보기/큰 책장에서 코일 크기를 맞추기 위한 배율.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    switch (normalizeCoverBinding(binding)) {
      case 'spiral':
        _coils(canvas, size, ring: false);
      case 'ring':
        _coils(canvas, size, ring: true);
      case 'stitch':
        _stitch(canvas, size);
      case 'staple':
        _staple(canvas, size);
      case 'disc':
        _disc(canvas, size);
      // plain: 기존 책등 띠만 사용.
    }
  }

  /// 스프링/링 — 왼쪽 가장자리를 감싸는 흰 코일 루프.
  void _coils(Canvas canvas, Size size, {required bool ring}) {
    final stroke = (ring ? 2.6 : 2.0) * scale;
    final wire = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final spacing = (ring ? 26.0 : 14.0) * scale;
    final cx = 6.0 * scale;
    final w = (ring ? 13.0 : 9.0) * scale;
    final h = (ring ? 9.0 : 6.0) * scale;
    for (double y = spacing; y < size.height - spacing * 0.4; y += spacing) {
      final rect = Rect.fromCenter(center: Offset(cx, y), width: w, height: h);
      canvas.drawArc(
          rect.shift(Offset(0.6 * scale, 0.6 * scale)), -2.6, 4.4, false, shadow);
      canvas.drawArc(rect, -2.6, 4.4, false, wire);
    }
  }

  /// 실제본 — 가장자리 안쪽의 점선 박음질.
  void _stitch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;
    final x = 11.0 * scale;
    final dash = 6.0 * scale;
    final gap = 5.0 * scale;
    for (double y = dash; y < size.height - dash; y += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dash), paint);
    }
  }

  /// 중철 — 책등 가운데를 따라 박힌 흰 스테이플(⊓) 몇 개.
  void _staple(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;
    final x = 6.0 * scale;
    final w = 5.0 * scale; // 다리 사이 반폭
    final leg = 7.0 * scale;
    for (final f in const [0.28, 0.5, 0.72]) {
      final y = size.height * f;
      final path = Path()
        ..moveTo(x - w, y + leg / 2)
        ..lineTo(x - w, y - leg / 2)
        ..lineTo(x + w, y - leg / 2)
        ..lineTo(x + w, y + leg / 2);
      canvas.drawPath(path.shift(Offset(0.6 * scale, 0.6 * scale)), shadow);
      canvas.drawPath(path, paint);
    }
  }

  /// 디스크 — 디스크제본처럼 가장자리에 박힌 흰 원반들.
  void _disc(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.18);
    final ring = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    final r = 4.2 * scale;
    final spacing = 22.0 * scale;
    final cx = 7.0 * scale;
    for (double y = spacing; y < size.height - spacing * 0.4; y += spacing) {
      canvas.drawCircle(Offset(cx + 0.6 * scale, y + 0.6 * scale), r, shadow);
      canvas.drawCircle(Offset(cx, y), r, fill);
      canvas.drawCircle(Offset(cx, y), r, ring);
    }
  }

  @override
  bool shouldRepaint(CoverBindingPainter old) =>
      old.binding != binding || old.scale != scale;
}
