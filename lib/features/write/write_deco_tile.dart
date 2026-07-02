part of 'write_screen.dart';

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
    final preview = contentPreview(content);
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
                    if (preview.isNotEmpty)
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
                          child: Text(preview,
                              maxLines: 1,
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
