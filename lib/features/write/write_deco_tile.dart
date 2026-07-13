part of 'write_screen.dart';

/// Page-canvas/inline-photo editing state for the write screen, factored out of
/// _WriteScreenState alongside _PhotoDecoState to keep write_screen.dart under
/// the 500-line limit.
///
/// Phase 2(탭 통합)부터 페이지 꾸미기는 별도 전체화면 편집기가 아니라 글쓰기 화면
/// 안에서 바로 이뤄진다. 살아있는 캔버스 상태(속지·바탕색·레이어)는
/// [PageDecoEditorController]가 소유하고, 저장·프리필은 그 캔버스를 JSON으로
/// 직렬화/역직렬화해 오간다.
mixin _PageDecoState on ConsumerState<WriteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  /// 글쓰기 화면에 얹은 페이지 꾸미기 캔버스의 살아있는 상태.
  final _deco = PageDecoEditorController();

  /// 본문 흐름 사이에 끼운 사진들(InlinePhoto JSON, null=없음).
  String? _flowPhotos;

  /// 저장/프리필용 캔버스 JSON. 안 꾸몄으면(빈 캔버스) null.
  String? get _pageCanvasJson =>
      _deco.isBlank ? null : encodePageCanvas(_deco.canvas);

  /// 본문 흐름 사이에 끼울 사진을 고르는 편집기를 연다.
  Future<void> _editInlinePhotos() async {
    final v = await editInlinePhotosFlow(context,
        content: _contentCtrl.text, current: _flowPhotos);
    if (mounted) setState(() => _flowPhotos = v);
  }
}
