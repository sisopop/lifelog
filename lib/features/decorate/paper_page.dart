// 본문 글을 "종이 페이지" 위에 올려 보여주는 배경 위젯.
//
// 속지 바탕색 + 무늬(줄/모눈/도트)를 [canvas]에서 읽어 그리고, 그 위에 [child]
// (글쓰기 화면의 편집용 TextField 또는 기록 상세의 읽기전용 본문 Text)를 얹는다.
// 글쓰기 화면과 기록 상세가 이 위젯을 공유해 "쓴 글이 실제로 꾸민 종이 위에 보이는"
// 일관된 결과를 만든다. 무늬 간격은 폭에 비례(paperGapForWidth)해 어느 크기에서든
// 같은 밀도로 렌더된다.

import 'dart:math' as math;

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

/// Composites a decorated page for **read-only** display: paper background +
/// the entry's full body text (flowing naturally, never clipped) + decoration
/// layers placed on top — one visual instead of a canvas box shown above a
/// separate text block. Grows to fit the body, however long; each layer's
/// x/y (0..1) maps to an [Alignment] via [layerAlignment] so it lands in the
/// same relative spot no matter how tall the rendered page ends up. Shares
/// paint helpers with [PageCanvasView] so editor, write-screen preview and
/// this detail render stay visually identical. The entry detail screen shows
/// this when [shouldCompositePage] says so (decorated canvas, no legacy
/// inline-flow photos); otherwise it falls back to the old separate blocks.
class DecoratedPageView extends StatelessWidget {
  const DecoratedPageView({
    super.key,
    required this.canvas,
    required this.content,
    this.textStyle,
    this.padding = const EdgeInsets.all(16),
    this.showPaper = true,
  });

  final PageCanvas canvas;
  final String content;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  /// 자체 종이(크림/속지 무늬 + 테두리 + 그림자)를 그릴지. 기록 상세에서는 이
  /// 기록의 속지를 화면 전체 배경으로 한 번만 깔기 때문에 false로 넘겨, 글 위에
  /// 또 한 겹 종이 카드가 얹히던 "이중 속지"를 없앤다(본문·레이어만 투명하게
  /// 얹는다). 기본 true는 다른 미리보기 용도의 기존 동작을 지킨다.
  final bool showPaper;

  @override
  Widget build(BuildContext context) {
    final color = canvas.paperColorValue != null
        ? Color(canvas.paperColorValue!)
        : kCanvasPaperCream;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        // 본문이 짧아도 최소 한 장의 세로 페이지 높이를 확보한다. 이게 없으면
        // Stack이 짧은 본문 한 줄 높이로 쪼그라들어, 편집기에서 넓게 벌려 놓은
        // 꾸밈 레이어가 상세에서 좁은 영역에 전부 뭉쳐 보였다. 본문이 길면
        // 그 높이만큼 자연스럽게 늘어난다(레이어는 이 최종 높이 기준 상대 배치).
        final minHeight = w / kPageAspectRatio;
        final stack = Stack(
          children: [
            // 페이지 최소 높이를 잡아 주는 보이지 않는 자.
            SizedBox(width: w, height: minHeight),
            if (showPaper)
              Positioned.fill(
                child: CustomPaint(
                  painter: PageCanvasPaperPainter(canvas.paper,
                      gap: paperGapForWidth(w)),
                ),
              ),
            Padding(
              padding: padding,
              child: Text(content, style: textStyle),
            ),
            // 꾸밈 레이어: 편집기와 "완전히 같은" 방식으로 중심을 x·y 지점에
            // 맞춰 놓는다. 예전엔 Align(layerAlignment)로 놨는데, Align은 자식
            // 크기만큼 앵커가 밀려(가로로 childW*(x-0.5)만큼) 편집기(중심 배치)와
            // 위치가 어긋났다 — 특히 큰 사진 레이어에서 눈에 띄게 달라, 사용자가
            // "꾸미기 화면과 읽기 화면의 배치가 다르다"고 신고했다. LayoutBuilder로
            // 최종 페이지 크기(lw·lh)를 재어 Positioned+FractionalTranslation(-0.5)
            // 로 편집기(page_deco_playground `_layerWidget`)와 동일 좌표에 그린다.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, lc) {
                  final lw = lc.maxWidth;
                  final lh = lc.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final l in layersByZ(canvas))
                        Positioned(
                          left: l.x * lw,
                          top: l.y * lh,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: Transform.rotate(
                              angle: l.rotation * math.pi / 180,
                              child: decoLayerContent(
                                l,
                                stickerSize: 44 * l.scale,
                                boxWidth: l.boxW == null ? null : l.boxW! * lw,
                                boxHeight: l.boxH == null ? null : l.boxH! * lh,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
        // 상세에서는 배경 속지를 화면 전체에 이미 깔았으므로 투명하게 얹는다.
        if (!showPaper) return stack;
        return Container(
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
            child: stack,
          ),
        );
      },
    );
  }
}
