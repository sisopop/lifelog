part of 'write_screen.dart';

/// Page-canvas/inline-photo editing actions for the write screen, factored
/// out of _WriteScreenState alongside _PhotoDecoState to keep
/// write_screen.dart under the 500-line limit.
mixin _PageDecoState on ConsumerState<WriteScreen> {
  final _contentCtrl = TextEditingController();

  /// 내지 꾸미기 캔버스 JSON(null=꾸미기 없음).
  String? _pageCanvas;

  /// 본문 흐름 사이에 끼운 사진들(InlinePhoto JSON, null=없음).
  String? _flowPhotos;

  /// Opens the canvas editor; "완료" returns the edited canvas (null = clear).
  Future<void> _editPageCanvas() async {
    final nav = Navigator.of(context);
    await nav.push(MaterialPageRoute<void>(
      builder: (_) => PageDecoPlayground(
        title: '페이지 꾸미기',
        initial: decodePageCanvas(_pageCanvas),
        onDone: (canvas) {
          setState(() =>
              _pageCanvas = canvas == null ? null : encodePageCanvas(canvas));
          nav.pop();
        },
      ),
    ));
  }

  /// 본문 흐름 사이에 끼울 사진을 고르는 편집기를 연다.
  Future<void> _editInlinePhotos() async {
    final v = await editInlinePhotosFlow(context,
        content: _contentCtrl.text, current: _flowPhotos);
    if (mounted) setState(() => _flowPhotos = v);
  }
}

/// Entry point to the page-decoration canvas. Shows a read-only preview of the
/// saved canvas (if any) — with a one-line overlay of the body text, so the
/// writer sees their words laid over the decorated page — plus a button to open
/// the editor. Tapping either the preview or the button opens [PageDecoPlayground].
class _DecoratePageTile extends StatelessWidget {
  const _DecoratePageTile(
      {required this.canvasJson, required this.onEdit, this.content = ''});

  final String? canvasJson;
  final String content;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final canvas = decodePageCanvas(canvasJson);
    final decorated = canvas.layers.isNotEmpty || canvas.paper != PaperStyle.plain;
    final summary = pageCanvasSummary(canvas);
    final previewLines = contentPreviewLines(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decorated) ...[
          GestureDetector(
            onTap: onEdit,
            child: SizedBox(
              height: 160,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    PageCanvasView(canvas, stickerBaseSize: 28),
                    if (previewLines.isNotEmpty)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(previewLines.join('\n'),
                              maxLines: previewLines.length,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (summary != null) ...[
            Text('🎨 $summary',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            const SizedBox(height: 6),
          ],
        ],
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.brush_outlined, size: 18, color: AppColors.primary),
          label: Text(decorated ? '페이지 꾸미기 수정' : '페이지 꾸미기',
              style: const TextStyle(color: AppColors.primary)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
