// 본문 글을 "종이 페이지" 위에 올려 보여주는 배경 위젯.
//
// 속지 바탕색 + 무늬(줄/모눈/도트)를 [canvas]에서 읽어 그리고, 그 위에 [child]
// (글쓰기 화면의 편집용 TextField 또는 기록 상세의 읽기전용 본문 Text)를 얹는다.
// 글쓰기 화면과 기록 상세가 이 위젯을 공유해 "쓴 글이 실제로 꾸민 종이 위에 보이는"
// 일관된 결과를 만든다. 무늬 간격은 폭에 비례(paperGapForWidth)해 어느 크기에서든
// 같은 밀도로 렌더된다.

import 'package:flutter/material.dart';

import 'page_canvas.dart';
import 'page_canvas_view.dart';

class PaperPageBackground extends StatelessWidget {
  const PaperPageBackground({
    super.key,
    required this.canvas,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.minHeight = 220,
  });

  final PageCanvas canvas;
  final Widget child;
  final EdgeInsets padding;

  /// 종이 페이지의 최소 높이(본문이 짧아도 종이 느낌이 나도록).
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final color = canvas.paperColorValue != null
        ? Color(canvas.paperColorValue!)
        : kCanvasPaperCream;
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCanvasGridLine.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: PageCanvasPaperPainter(canvas.paper,
                      gap: paperGapForWidth(c.maxWidth)),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
