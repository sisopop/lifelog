part of 'page_deco_editor.dart';

/// 페이지 꾸미기 캔버스 본체(종이 배경 + 일기 글 + 레이어들). 상태는
/// [PageDecoEditorController]가 소유하고, 이 위젯은 그것을 구독해 그린다. 크기는
/// 바깥(호스트)의 SizedBox가 폭 기준으로 정해 주므로 여기서는 세로 비율
/// (AspectRatio)을 강제하지 않고 주어진 상자를 꽉 채운다. (상세 합성뷰
/// DecoratedPageView와 같은 kPageAspectRatio 세로 비율로 그려지도록 바깥에서
/// 폭*4/3 높이를 넘겨준다 → WYSIWYG 유지.)
///
/// [interactive]가 false면 레이어를 그대로 보여주되 탭·드래그·삭제 제스처를 모두
/// 끈다(글쓰기/속지/바탕색 탭에서 배경으로만 볼 때 사용).
class PageDecoCanvas extends StatelessWidget {
  const PageDecoCanvas({
    super.key,
    required this.controller,
    this.titleText = '',
    this.contentText = '',
    this.interactive = true,
  });

  final PageDecoEditorController controller;
  final String titleText;
  final String contentText;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final canvas = controller.canvas;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: canvas.paperColorValue != null
                  ? Color(canvas.paperColorValue!)
                  : kCanvasPaperCream, // 기본 크림 속지
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
                final title = titleText.trim();
                final baseLines = pageBaseLines(contentText);
                final hasDiary = title.isNotEmpty || baseLines.isNotEmpty;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: interactive ? controller.deselect : null,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PageCanvasPaperPainter(canvas.paper),
                        ),
                      ),
                      // 실제 쓴 일기(제목+본문)를 종이 바탕에 깔아, 완성된 모습
                      // 위에 스티커를 올리게 한다(WYSIWYG). 탭/드래그는 아래 레이어로 통과.
                      if (hasDiary)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (title.isNotEmpty) ...[
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  if (baseLines.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        baseLines.join('\n'),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.6,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (canvas.isEmpty && !hasDiary)
                        const Center(
                          child: Text(
                            '아래 스티커를 눌러 올려보세요\n끌어서 옮기고, 골라서 키우거나 돌릴 수 있어요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textHint, height: 1.5),
                          ),
                        ),
                      for (final l in layersByZ(canvas)) _layerWidget(l, w, h),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _layerWidget(DecoLayer l, double w, double h) {
    final selected = interactive && l.id == controller.selectedId;
    return Positioned(
      left: l.x * w,
      top: l.y * h,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              // 선택 시 위·오른쪽에 삭제 배지가 앉을 자리를 비운다. 이렇게 해야
              // 배지가 레이어의 히트영역(Stack 크기) 안에 들어와 탭이 먹는다.
              // (Stack 밖으로 삐져나간 요소는 보이기만 하고 탭은 무시된다.)
              padding: selected
                  ? const EdgeInsets.only(top: 14, right: 14)
                  : EdgeInsets.zero,
              child: GestureDetector(
                onTap: interactive ? () => controller.selectLayer(l.id) : null,
                onPanUpdate: interactive
                    ? (d) => controller.dragLayer(l, d.delta.dx, d.delta.dy, w, h)
                    : null,
                child: Transform.rotate(
                  angle: l.rotation * math.pi / 180,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: selected
                        ? BoxDecoration(
                            border:
                                Border.all(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          )
                        : null,
                    child: decoLayerContent(l, stickerSize: 44 * l.scale),
                  ),
                ),
              ),
            ),
            // 선택된 레이어 위에 바로 뜨는 삭제 배지. 툴바 맨 끝까지 스크롤하지
            // 않아도 눈에 보이는 곳에서 한 번에 지울 수 있게 한다.
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.deleteSelected,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.moodHard,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
