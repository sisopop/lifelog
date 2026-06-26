import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'cover_texture.dart';
import 'cover_texture_images.dart';

/// 표지 '면' 전체에 실사 재질(가죽/크라프트/패브릭) 질감을 입히는 페인터.
///
/// 흑백(휘도) 심리스 텍스처 이미지를 타일링해 `BlendMode.multiply`로 표지
/// 그라데이션에 곱한다 → 색은 유지된 채 가죽 결·종이 섬유·직물 짜임만 들어간다.
/// 'none'은 아무것도 그리지 않는다(매끈한 단색).
///
/// 바깥 [ClipRRect]가 별도 레이어를 만들어 곱하기 대상(표지 그라데이션)이
/// 사라질 수 있어, 페인터 안에서 [Canvas.saveLayer]로 그라데이션을 먼저 깔고
/// 그 위에 텍스처를 곱한다 → 어떤 위젯 트리에서도 결과가 일정하다.
class CoverTexturePainter extends CustomPainter {
  CoverTexturePainter(this.texture, this.color, {this.scale = 1.0})
      : super(repaint: CoverTextureImages.instance);

  /// cover_texture.dart의 재질 id.
  final String texture;

  /// 표지 베이스 색(곱하기 전에 깔 그라데이션). Journal.coverColor.
  final Color color;

  /// 작은 미리보기/큰 책장에서 결 크기를 맞추기 위한 배율(작을수록 결이 촘촘).
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizeCoverTexture(texture) == kDefaultCoverTexture) return;
    final image = CoverTextureImages.instance.imageFor(texture);
    if (image == null) return; // 아직 로딩 중 — 로드되면 리페인트.

    final rect = Offset.zero & size;
    // 곱하기 대상이 항상 존재하도록 그라데이션을 같은 레이어에 먼저 깐다.
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [color, color.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    // 512px 원본을 표지 폭의 약 1.3배로 반복(scale로 미세 조정).
    final tile = size.width / image.width * 1.3 * scale;
    final matrix = Matrix4.diagonal3Values(tile, tile, 1).storage;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          matrix,
        )
        ..blendMode = BlendMode.multiply,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CoverTexturePainter old) =>
      old.texture != texture ||
      old.color != color ||
      old.scale != scale;
}
