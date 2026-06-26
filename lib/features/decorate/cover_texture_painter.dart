import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cover_texture.dart';

/// 표지 '면' 위에 재질(가죽/크라프트/패브릭) 질감을 절차적으로 입히는 페인터.
/// 베이스 색 위에 반투명 음영/하이라이트만 덮으므로 어떤 표지 색과도 어울린다.
/// 'none'은 아무것도 그리지 않습니다(매끈한 단색).
///
/// 난수는 고정 시드 LCG로 결정적 — 리페인트마다 동일한 무늬가 나온다.
class CoverTexturePainter extends CustomPainter {
  const CoverTexturePainter(this.texture, {this.scale = 1.0});

  /// cover_texture.dart의 재질 id.
  final String texture;

  /// 작은 미리보기/큰 책장에서 질감 밀도를 맞추기 위한 배율.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    switch (normalizeCoverTexture(texture)) {
      case 'leather':
        _leather(canvas, size);
      case 'kraft':
        _kraft(canvas, size);
      case 'fabric':
        _fabric(canvas, size);
      // none: 아무것도 그리지 않음.
    }
  }

  // 결정적 의사난수(0~1). 시드만 바꿔 다른 분포를 얻는다.
  double _rnd(int seed) {
    final x = math.sin(seed * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
  }

  /// 가죽 — 가장자리 비네팅 + 자잘한 페블 그레인 + 부드러운 주름 + 상단 광택.
  void _leather(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // 가장자리로 갈수록 어두워지는 비네팅(가죽의 깊이감).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.22),
          ],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
    // 페블 그레인 — 어두운/밝은 점을 촘촘히 흩뿌려 가죽 결을 만든다.
    final count = (size.width * size.height / 26 * scale).clamp(40, 1400).toInt();
    for (var i = 0; i < count; i++) {
      final x = _rnd(i * 2 + 1) * size.width;
      final y = _rnd(i * 2 + 2) * size.height;
      final r = (0.5 + _rnd(i + 7) * 1.4) * scale;
      final dark = _rnd(i + 3) > 0.5;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = (dark ? Colors.black : Colors.white)
              .withValues(alpha: dark ? 0.10 : 0.07),
      );
    }
    // 부드러운 주름 몇 줄(밝은 능선 + 아래 그림자).
    final creases = (3 * scale).clamp(2, 5).toInt();
    for (var i = 0; i < creases; i++) {
      final y = size.height * (0.2 + 0.6 * _rnd(i * 9 + 4));
      final path = Path()..moveTo(0, y);
      path.cubicTo(size.width * 0.3, y - 6 * scale, size.width * 0.6,
          y + 7 * scale, size.width, y - 3 * scale);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale,
      );
      canvas.drawPath(
        path.shift(Offset(0, 1.4 * scale)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale,
      );
    }
    // 상단 광택(가죽 특유의 은은한 반사).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35],
        ).createShader(rect),
    );
  }

  /// 크라프트 — 따뜻한 갈색 워시 + 짧은 섬유 플렉 + 가로 결.
  void _kraft(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // 따뜻한 톤 워시(색을 크라프트지 쪽으로 살짝 끌어온다).
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF8A5A33).withValues(alpha: 0.16),
    );
    // 섬유 플렉 — 짧은 선들을 임의 각도로 흩뿌려 종이 섬유를 만든다.
    final count = (size.width * size.height / 30 * scale).clamp(40, 1200).toInt();
    for (var i = 0; i < count; i++) {
      final x = _rnd(i * 3 + 1) * size.width;
      final y = _rnd(i * 3 + 2) * size.height;
      final len = (1.5 + _rnd(i + 11) * 3.0) * scale;
      final ang = _rnd(i + 5) * math.pi; // 0~180°.
      final dx = math.cos(ang) * len;
      final dy = math.sin(ang) * len * 0.5; // 가로로 살짝 눕힘.
      final light = _rnd(i + 13) > 0.5;
      canvas.drawLine(
        Offset(x - dx, y - dy),
        Offset(x + dx, y + dy),
        Paint()
          ..color = (light
                  ? const Color(0xFFF0E2C8)
                  : const Color(0xFF5A3D2B))
              .withValues(alpha: light ? 0.12 : 0.14)
          ..strokeWidth = 0.9 * scale,
      );
    }
    // 가로 결(종이 누르는 결).
    final step = (7 * scale).clamp(4.0, 12.0);
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.03)
          ..strokeWidth = 0.8 * scale,
      );
    }
  }

  /// 패브릭 — 가로/세로 실 격자(짜임) + 밝고 어두운 실 교차로 직물 느낌.
  void _fabric(Canvas canvas, Size size) {
    final step = (6 * scale).clamp(4.0, 11.0);
    // 세로 실.
    var col = 0;
    for (double x = 0; x < size.width; x += step) {
      final light = col.isEven;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = (light ? Colors.white : Colors.black)
              .withValues(alpha: light ? 0.08 : 0.07)
          ..strokeWidth = step * 0.5,
      );
      col++;
    }
    // 가로 실(세로 실 위로 교차해 짜임 형성).
    var row = 0;
    for (double y = 0; y < size.height; y += step) {
      final light = row.isOdd;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = (light ? Colors.white : Colors.black)
              .withValues(alpha: light ? 0.07 : 0.06)
          ..strokeWidth = step * 0.5,
      );
      row++;
    }
  }

  @override
  bool shouldRepaint(CoverTexturePainter old) =>
      old.texture != texture || old.scale != scale;
}
