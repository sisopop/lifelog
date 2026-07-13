part of 'write_screen.dart';

/// 글쓰기 화면 하단 탭 라벨. 순서가 인덱스이므로 [kWriteLayerTabs]와 함께 맞춘다.
const List<String> kWriteTabs = ['글쓰기', '속지', '바탕색', '사진', '테이프', '스티커'];

/// 캔버스를 레이어 드래그 모드(상호작용)로 켜는 탭 인덱스(사진·테이프·스티커).
/// 나머지 탭에서는 캔버스가 읽기전용 배경(WYSIWYG 미리보기)이 된다.
const Set<int> kWriteLayerTabs = {3, 4, 5};

/// 글쓰기 화면 본문.
///
/// 구조(위→아래, 세로 [Column]):
///   1) 메타필드(저널/제목/날짜/감정/날씨) — 상단 **고정**(스크롤 안 함)
///   2) 공용 미리보기 캔버스(가로 100%) — 모든 탭에서 **항상 표시**, 실시간 반영
///   3) [TabBar] (글쓰기/속지/바탕색/사진/테이프/스티커)
///   4) [TabBarView] — 그 탭의 컨트롤만:
///      - 글쓰기 탭: 본문 입력 + 프롬프트 + 태그 + 첨부 + 저장
///      - 속지/바탕색: 종이·색상 선택
///      - 사진/테이프/스티커: 레이어 편집 컨트롤(캔버스에서 끌어 배치)
///
/// 캔버스를 탭 안이 아닌 공용 영역에 두는 이유: 글을 쓰면서도, 속지를 고르면서도
/// 완성 모습(미리보기)을 항상 같은 자리에서 보게 하기 위함. 글쓰기 탭에서 본문을
/// 입력하면 위 캔버스에 즉시 비치고(WYSIWYG), 속지/바탕색을 바꾸면 배경이,
/// 사진/테이프/스티커를 올리면 레이어가 그 위에 실시간으로 얹힌다.
///
/// 상태는 모두 [_WriteScreenState] `s`가 소유하고, 이 위젯은 그것을 읽어 그린다.
class _WriteCanvasBody extends ConsumerWidget {
  const _WriteCanvasBody(this.s);

  final _WriteScreenState s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, box) {
        final body = box.maxHeight;
        final fullWidth = box.maxWidth - 32; // 좌우 16 여백
        final ideal = fullWidth / kPageAspectRatio; // 세로 3:4 기준 높이
        // 메타는 화면의 최대 42%까지만 차지(넘치면 그 안에서만 스크롤). 감정·날씨
        // 카드까지 다 고정하면 화면의 ~76%라 미리보기+탭이 안 들어가기 때문.
        final metaMax = body * 0.42;
        // 미리보기 캔버스: 가로 100% 고정. 세로는 3:4가 들어가면 3:4, 아니면 화면의
        // 36%까지(전체폭 유지 → 위쪽 미리보기 띠).
        final canvasMax = body * 0.36;
        final canvasH = ideal < canvasMax ? ideal : canvasMax;
        final interactive = kWriteLayerTabs.contains(s._tab.index);
        return Column(
          children: [
            // 1) 메타필드: 상단 고정(넘칠 때만 내부 스크롤)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: metaMax),
              child: SingleChildScrollView(child: _metaHeader(context, ref)),
            ),
            const Divider(height: 1),
            // 2) 공용 미리보기 캔버스(가로 100%, 항상 표시)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Center(
                child: SizedBox(
                  width: fullWidth,
                  height: canvasH,
                  child: PageDecoCanvas(
                    controller: s._deco,
                    titleText: s._titleCtrl.text,
                    contentText: s._contentCtrl.text,
                    interactive: interactive,
                  ),
                ),
              ),
            ),
            // 3) 탭바
            TabBar(
              controller: s._tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final t in kWriteTabs) Tab(text: t)],
            ),
            // 4) 탭 콘텐츠(남는 세로 공간 전부)
            Expanded(
              child: TabBarView(
                controller: s._tab,
                children: [
                  _writeTab(context, ref),
                  _paperTab(),
                  _colorTab(),
                  _photoTab(context),
                  _tapeTab(context),
                  _stickerTab(context),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── 1) 상단 고정 메타(저널/제목/날짜/감정/날씨) ─────────────────────────────

  Widget _metaHeader(BuildContext context, WidgetRef ref) {
    final journals =
        ref.watch(journalsProvider).asData?.value ?? const <Journal>[];
    final jid = s._targetJournalId;
    final journal = journals.where((j) => j.journalId == jid).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!s._isEditing && journal != null) ...[
            _JournalSelector(
              journal: journal,
              canSwitch: s._canSwitchJournal,
              onTap: s._canSwitchJournal ? () => s._pickJournal(journals) : null,
            ),
            _NewEntryOrdinal(journalId: jid),
            const SizedBox(height: 8),
          ],
          _TitleField(
            controller: s._titleCtrl,
            contentText: s._contentCtrl.text,
            onApply: (t) {
              s._titleCtrl.text = t;
              s.refresh(() {});
            },
          ),
          const Divider(),
          DateField(date: s._date, onTap: s._pickDate),
          if (!s._isEditing) _SameDayCount(journalId: jid, date: s._date),
          const SizedBox(height: 8),
          MoodField(
            value: s._mood,
            contentText: s._contentCtrl.text,
            onChanged: (m) => s.refresh(() => s._mood = m),
          ),
          const SizedBox(height: 12),
          WeatherField(
            value: s._weather,
            onChanged: (w) => s.refresh(() => s._weather = w),
          ),
        ],
      ),
    );
  }

  // ── 캔버스 요소 추가 헬퍼(사진/글자 레이어) ──────────────────────────────

  Future<void> _addCanvasPhoto(BuildContext context) async {
    final data = await pickCanvasPhotoData(context, s._picker);
    if (data != null) s._deco.addPhotoData(data);
  }

  Future<void> _addCanvasText(BuildContext context) async {
    final input = await showTextLayerDialog(context);
    if (input != null) s._deco.addTextInput(input);
  }

  // ── 4-글쓰기 탭: 본문 입력 + 프롬프트 + 태그 + 첨부 + 저장(메타 제외) ────────

  Widget _writeTab(BuildContext context, WidgetRef ref) {
    final journals =
        ref.watch(journalsProvider).asData?.value ?? const <Journal>[];
    final jid = s._targetJournalId;
    final journal = journals.where((j) => j.journalId == jid).firstOrNull;
    final shared = journal != null && journal.type != JournalType.personal;
    final canSave = canSaveEntry(content: s._contentCtrl.text);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // 본문: 위 캔버스에 실시간으로 비친다(WYSIWYG).
        TextField(
          controller: s._contentCtrl,
          minLines: 6,
          maxLines: null,
          onChanged: (_) => s.refresh(() {}),
          style: const TextStyle(
              fontSize: 15, height: 1.6, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '오늘 어떤 하루였나요?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        _ContentMeta(s._contentCtrl.text),
        if (s._contentCtrl.text.trim().isEmpty) ...[
          const SizedBox(height: 12),
          WritingPromptCard(
            prompt: ref.watch(writingPromptProvider),
            onUse: () {
              final p = ref.read(writingPromptProvider);
              s._contentCtrl.text = '$p\n';
              s._contentCtrl.selection =
                  TextSelection.collapsed(offset: s._contentCtrl.text.length);
              s.refresh(() {});
            },
            onRefresh: () =>
                ref.read(writingPromptIndexProvider.notifier).next(),
          ),
        ],
        if ((s._location ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              avatar: const Icon(Icons.place, size: 18),
              label: Text(s._location!.trim()),
              onPressed: s._editLocation,
              onDeleted: () => s.refresh(() => s._location = null),
            ),
          ),
        ],
        if (s._photoPaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PhotoThumbnailsRow(
            photoPaths: s._photoPaths,
            photoFrames: s._photoFrames,
            photoStickers: s._photoStickers,
            photoTapes: s._photoTapes,
            photoMemos: s._photoMemos,
            photoAspects: s._photoAspects,
            photoFilters: s._photoFilters,
            photoCrops: s._photoCrops,
            onRemove: (i) => s.refresh(() {
              s._photoPaths.removeAt(i);
              s._removePhotoDecoAt(i);
            }),
            onFramePicked: (i, frameId) =>
                s.refresh(() => s._setFrameAt(i, frameId)),
            onStickerPicked: (i, emoji) =>
                s.refresh(() => s._setStickerAt(i, emoji)),
            onTapePicked: (i, tapeId) =>
                s.refresh(() => s._setTapeAt(i, tapeId)),
            onMemoPicked: (i, memo) =>
                s.refresh(() => s._setMemoAt(i, memo)),
            onAspectPicked: (i, aspectId) =>
                s.refresh(() => s._setAspectAt(i, aspectId)),
            onFilterPicked: (i, filterId) =>
                s.refresh(() => s._setFilterAt(i, filterId)),
            onCropPicked: (i, cropId) =>
                s.refresh(() => s._setCropAt(i, cropId)),
          ),
        ],
        _EntryTags(
          tags: s._tags,
          onRemove: (t) => s.refresh(() => s._tags.remove(t)),
        ),
        _HashtagSuggestions(
          suggestions: extractHashtagSuggestions(s._contentCtrl.text, s._tags),
          onAdd: s._addTagDirect,
        ),
        _FrequentTagChips(current: s._tags, onAdd: s._addTagDirect),
        const SizedBox(height: 16),
        _AttachRow(
          onPhoto: s._pickPhotos,
          onLocation: s._editLocation,
          onTag: s._addTag,
          onEmoji: () => pickAndInsertEmoji(context, s._contentCtrl)
              .then((_) => s.mounted ? s.refresh(() {}) : null),
        ),
        // "본문 사이 사진"은 신규 진입을 숨김. 기존 기록에 데이터가 있을 때만 노출.
        if (decodeInlinePhotos(s._flowPhotos).isNotEmpty) ...[
          const SizedBox(height: 12),
          InlinePhotoTile(
              flowPhotos: s._flowPhotos, onEdit: s._editInlinePhotos),
        ],
        const SizedBox(height: 24),
        if (s._isEditing)
          ElevatedButton(
            onPressed: canSave
                ? () => s._save(
                    visibility: s._editing?.visibility ?? EntryVisibility.private)
                : null,
            child: const Text('수정 저장'),
          )
        else if (shared)
          ElevatedButton(
            onPressed: canSave
                ? () => s._save(visibility: EntryVisibility.link)
                : null,
            child: const Text('함께 저장'),
          )
        else ...[
          ElevatedButton(
            onPressed: canSave
                ? () => s._save(visibility: EntryVisibility.private)
                : null,
            child: const Text('비공개 저장'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: canSave
                ? () => s._save(visibility: EntryVisibility.link)
                : null,
            child: const Text('공유하며 저장',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  // ── 4-꾸미기 탭들: 각 탭의 컨트롤만(캔버스는 위 공용 영역에 이미 표시됨) ──────

  // child를 빌더로 받아 AnimatedBuilder 안에서 매번 새로 만든다.
  // (미리 만든 위젯을 넘기면 컨트롤러 값이 최초 빌드에 고정돼 갱신 안 됨)
  Widget _tabScroll(Widget Function() build) => AnimatedBuilder(
        animation: s._deco,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          child: build(),
        ),
      );

  Widget _paperTab() => _tabScroll(
        () => PaperSelector(
          paper: s._deco.canvas.paper,
          paperColorValue: s._deco.canvas.paperColorValue,
          onPaperChanged: s._deco.setPaperStyle,
          onColorChanged: s._deco.setPaperColorValue,
          showColor: false,
        ),
      );

  Widget _colorTab() => _tabScroll(
        () => PaperSelector(
          paper: s._deco.canvas.paper,
          paperColorValue: s._deco.canvas.paperColorValue,
          onPaperChanged: s._deco.setPaperStyle,
          onColorChanged: s._deco.setPaperColorValue,
          showPaper: false,
        ),
      );

  Widget _photoTab(BuildContext context) => _tabScroll(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text('사진·글자를 얹고, 위 미리보기에서 끌어 옮기세요',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            ),
            _decoPalette(context, showTape: false, showSticker: false),
          ],
        ),
      );

  Widget _tapeTab(BuildContext context) => _tabScroll(
      () => _decoPalette(context, showPhoto: false, showSticker: false));

  Widget _stickerTab(BuildContext context) => _tabScroll(
      () => _decoPalette(context, showPhoto: false, showTape: false));

  Widget _decoPalette(
    BuildContext context, {
    bool showPhoto = true,
    bool showTape = true,
    bool showSticker = true,
  }) {
    return DecoPalette(
      categoryIndex: s._deco.categoryIndex,
      onCategory: s._deco.setCategory,
      onAddPhoto: () => _addCanvasPhoto(context),
      onAddText: () => _addCanvasText(context),
      onAddTape: s._deco.addTape,
      onAddSticker: s._deco.addSticker,
      showPhoto: showPhoto,
      showTape: showTape,
      showSticker: showSticker,
    );
  }
}
