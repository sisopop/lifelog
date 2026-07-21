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
    final isBox = l.kind == DecoKind.textbox;
    final stickerSize = 44 * l.scale;
    final boxW = isBox ? (l.boxW ?? kDefaultTextBoxW) * w : null;
    final boxH = isBox ? (l.boxH ?? kDefaultTextBoxH) * h : null;
    // 텍스트박스를 고르면 상자 안에서 바로 글을 쓸 수 있게 리치 편집기로 바꾼다.
    // 그 외(또는 미선택 텍스트박스)는 읽기용 렌더를 그대로 보여준다.
    final Widget inner = (isBox && selected)
        ? TextBoxRichEditor(
            key: ValueKey('tbedit-${l.id}'),
            richValue: l.richValue,
            plain: l.value,
            fontId: l.fontId,
            width: boxW!,
            height: boxH!,
            fontSize: stickerSize * 0.4,
            baseColor: l.colorValue == null
                ? AppColors.textPrimary
                : Color(l.colorValue!),
            onChanged: (plain, richJson) =>
                controller.setBoxRich(l.id, plain, richJson),
          )
        : decoLayerContent(l,
            stickerSize: stickerSize, boxWidth: boxW, boxHeight: boxH);
    return Positioned(
      left: l.x * w,
      top: l.y * h,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        // 회전을 레이어 본체 + 손잡이(삭제·회전·크기조절)를 모두 감싸도록 바깥에
        // 두어, 레이어가 돌아가면 세 손잡이도 모서리를 따라 함께 회전한다.
        child: Transform.rotate(
          angle: l.rotation * math.pi / 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                // 선택 시 네 모서리에 손잡이가 앉을 자리를 사방으로 비운다. 이렇게
                // 해야 손잡이가 레이어의 히트영역(Stack 크기) 안에 들어와 탭·드래그가
                // 먹는다(Stack 밖 요소는 보이기만 하고 무시).
                padding: selected
                    ? const EdgeInsets.all(14)
                    : EdgeInsets.zero,
                child: GestureDetector(
                  onTap:
                      interactive ? () => controller.selectLayer(l.id) : null,
                  onPanUpdate: interactive
                      ? (d) =>
                          controller.dragLayer(l, d.delta.dx, d.delta.dy, w, h)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: selected
                        ? BoxDecoration(
                            border:
                                Border.all(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          )
                        : null,
                    child: inner,
                  ),
                ),
              ),
              // 손잡이 3개(우상 삭제·좌하 회전·우하 확대축소)는 Transform.rotate 안에 있어
              // 레이어와 함께 회전한다. 드래그 델타(d.delta)는 항상 화면(글로벌) 좌표라 회전
              // 여부와 무관하게 크기조절·회전 계산은 그대로 동작한다.
              if (selected) ...[
                // 우상단: 삭제 배지.
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
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
                // 좌하단 코너: 회전 전용 손잡이(끌면 레이어가 돌아간다).
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _CornerHandle(
                    icon: Icons.rotate_right,
                    onDrag: (d) =>
                        controller.rotateLayer(l, d.delta.dx, d.delta.dy),
                  ),
                ),
                // 우하단 코너: 확대축소(좌상단 고정, 오른쪽·아래로 끌면 커진다. 비율 미유지).
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _CornerHandle(
                    icon: Icons.open_in_full,
                    onDrag: (d) =>
                        controller.resizeBox(l, d.delta.dx, d.delta.dy, w, h),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}

/// 레이어의 변·코너에 붙는 **단일 기능** 원형 손잡이(가로 조절·세로 조절·회전 중 하나만).
/// 드래그 델타를 그대로 [onDrag]로 넘긴다(컨트롤러가 글로벌 좌표로 계산하므로 레이어가
/// 회전돼 있어도 그대로 동작). [icon]으로 어떤 조작인지 표시한다.
class _CornerHandle extends StatelessWidget {
  const _CornerHandle({required this.icon, required this.onDrag});

  final IconData icon;
  final GestureDragUpdateCallback onDrag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: onDrag,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

