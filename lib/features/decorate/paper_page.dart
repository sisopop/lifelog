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

/// 꾸미기 캔버스의 "바탕 글"로 얹을 본문 줄들. 사용자가 실제로 쓴 글이 종이 위에
/// 보이고 그 주변으로 스티커를 놓게 하려고, 편집기가 이 줄들을 배경으로 깔아준다.
/// 각 줄은 trim하고 빈 줄은 버린다. 최대 [maxLines]줄까지 돌려주며, 본문의 보이는
/// 줄이 그보다 많으면 마지막 줄 끝에 "…"를 붙여 잘렸음을 나타낸다. 보이는 글이
/// 없으면 빈 리스트(호출부가 대신 안내 문구를 보여준다). 폭에 따른 줄바꿈은 렌더
/// 위젯이 맡고, 이 함수는 논리적 줄 수만 제한한다. 순수·top-level이라 단위 테스트 가능.
List<String> pageBaseLines(String content, {int maxLines = 16}) {
  final all = <String>[];
  for (final line in content.split('\n')) {
    final t = line.trim();
    if (t.isNotEmpty) all.add(t);
  }
  if (all.length <= maxLines) return all;
  final shown = all.take(maxLines).toList();
  shown[shown.length - 1] = '${shown.last}…';
  return shown;
}

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
