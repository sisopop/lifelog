import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/widgets/photo.dart';
import 'page_canvas.dart';
import 'washi_tape_catalog.dart';

// 캔버스 색 토큰 — 디자인 가이드 v1.0 캔버스(아날로그 질감) 팔레트.
const Color kCanvasPaperCream = Color(0xFFFFF8F0); // 속지 크림 바탕
const Color kCanvasGridLine = Color(0xFFE0D5C5); // 줄/모눈 선
const Color kCanvasDot = Color(0xFFCFC3B0); // 도트 점

/// 저장된 [PageCanvas]를 **읽기 전용**으로 렌더하는 위젯(탭·드래그 없음).
///
/// 편집기([PageDecoPlayground])와 같은 좌표 규칙(x/y 0~1 중심비율·scale·rotation)
/// 으로 그리므로 편집 결과가 기록 상세/미리보기에서 동일하게 재현된다. 크림 속지
/// 배경 + 속지 무늬 + z순서 레이어를 [aspectRatio](기본 세로 페이지) 비율로 그린다.
class PageCanvasView extends StatelessWidget {
  const PageCanvasView(
    this.canvas, {
    super.key,
    this.aspectRatio = 3 / 4,
    this.stickerBaseSize = 44,
  });

  final PageCanvas canvas;
  final double aspectRatio;

  /// scale=1 스티커의 기본 글자 크기. 미리보기를 작게 쓰려면 줄인다.
  final double stickerBaseSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: canvas.paperColorValue != null
                ? Color(canvas.paperColorValue!)
                : kCanvasPaperCream,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: PageCanvasPaperPainter(canvas.paper)),
                  ),
                  for (final l in layersByZ(canvas)) _layer(l, w, h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _layer(DecoLayer l, double w, double h) {
    return Positioned(
      left: l.x * w,
      top: l.y * h,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(
          angle: l.rotation * math.pi / 180,
          child: decoLayerContent(l, stickerSize: stickerBaseSize * l.scale),
        ),
      ),
    );
  }
}

/// 레이어 한 개의 시각 표현. 사진(photo)은 흰 액자(폴라로이드풍)로, 그 외
/// (텍스트·스티커)는 글자로 그린다. [stickerSize]는 scale이 이미 반영된 글자
/// 크기. 편집기와 읽기전용 뷰가 이 함수를 공유해 배치가 항상 일치한다.
Widget decoLayerContent(DecoLayer l, {required double stickerSize}) {
  Widget content = _decoLayerBody(l, stickerSize);
  // 좌우/위아래 뒤집기(거울상). 회전·배치는 상위에서 이미 적용된다.
  if (l.flipX || l.flipY) {
    content = Transform.flip(flipX: l.flipX, flipY: l.flipY, child: content);
  }
  // 반투명(기본 1.0=불투명). 낮추면 배경·아래 레이어가 비친다.
  if (l.opacity != 1.0) content = Opacity(opacity: l.opacity, child: content);
  return content;
}

Widget _decoLayerBody(DecoLayer l, double stickerSize) {
  if (l.kind == DecoKind.tape) {
    // 반투명 색 띠(가로로 길쭉). 회전(rotation)은 상위에서 이미 적용된다.
    return Container(
      width: stickerSize * 3.4,
      height: stickerSize * 0.8,
      color: washiTapeColor(l.value),
    );
  }
  if (l.kind == DecoKind.photo) {
    final side = stickerSize * 2.6; // 사진은 글자보다 크게
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PhotoView(l.value, width: side, height: side, iconSize: side * 0.4),
    );
  }
  final text = Text(
    l.value,
    style: TextStyle(
      fontSize: stickerSize,
      color: l.colorValue == null ? null : Color(l.colorValue!),
      fontWeight: l.bold ? FontWeight.w700 : null,
      fontStyle: l.italic ? FontStyle.italic : null,
      decoration: l.underline ? TextDecoration.underline : null,
    ),
  );
  if (l.bgColorValue == null) return text;
  // 형광펜 배경: 글자 뒤에 파스텔 블록을 깔고 살짝 여백·둥근 모서리를 준다.
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: stickerSize * 0.2,
      vertical: stickerSize * 0.06,
    ),
    decoration: BoxDecoration(
      color: Color(l.bgColorValue!),
      borderRadius: BorderRadius.circular(stickerSize * 0.16),
    ),
    child: text,
  );
}

/// 속지(배경) 무늬 페인터. 줄/모눈/도트를 일정 간격으로 채운다. plain은 아무것도
/// 그리지 않는다(크림 배경만). 편집기·읽기전용 뷰가 공유한다.
class PageCanvasPaperPainter extends CustomPainter {
  const PageCanvasPaperPainter(this.style, {this.gap = 28});

  final PaperStyle style;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case PaperStyle.plain:
        return;
      case PaperStyle.lined:
        final paint = Paint()
          ..color = kCanvasGridLine
          ..strokeWidth = 1;
        for (var y = gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case PaperStyle.grid:
        final paint = Paint()
          ..color = kCanvasGridLine
          ..strokeWidth = 1;
        for (var y = gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        for (var x = gap; x < size.width; x += gap) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
      case PaperStyle.dotted:
        final paint = Paint()..color = kCanvasDot;
        for (var y = gap; y < size.height; y += gap) {
          for (var x = gap; x < size.width; x += gap) {
            canvas.drawCircle(Offset(x, y), 1.4, paint);
          }
        }
    }
  }

  @override
  bool shouldRepaint(PageCanvasPaperPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.gap != gap;
}
