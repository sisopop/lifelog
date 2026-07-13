part of 'write_screen.dart';

/// 글쓰기 화면 하단 탭 라벨. 순서가 인덱스이므로 [kWriteLayerTabs]와 함께 맞춘다.
const List<String> kWriteTabs = ['글쓰기', '속지', '바탕색', '사진', '테이프', '스티커'];

/// 캔버스를 레이어 드래그 모드(상호작용)로 켜는 탭 인덱스(사진·테이프·스티커).
/// 나머지 탭에서는 캔버스가 읽기전용 배경(WYSIWYG 미리보기)이 된다.
const Set<int> kWriteLayerTabs = {3, 4, 5};

/// 글쓰기 화면 본문: 상단에 세로 3:4 캔버스를 폭 기준으로 고정하고, 그 아래
/// 탭바(글쓰기/속지/바탕색/사진/테이프/스티커)와 탭별 컨트롤 패널을 둔다.
/// 상태는 모두 [_WriteScreenState] `s`가 소유하고, 이 위젯은 그것을 읽어 그린다.
class _WriteCanvasBody extends ConsumerWidget {
  const _WriteCanvasBody(this.s);

  final _WriteScreenState s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactive = kWriteLayerTabs.contains(s._tab.index);
    return LayoutBuilder(
      builder: (context, box) {
        // 캔버스 폭 = 화면 폭 - 좌우 여백(32). 세로 = 폭 / (3/4)(세로 페이지). 단
        // 화면 절반을 넘지 않게 상한을 둬 아래 탭/패널이 항상 쓸 만큼 남게 한다.
        final fullWidth = box.maxWidth - 32;
        final ideal = fullWidth / kPageAspectRatio;
        final cap = box.maxHeight * 0.5;
        final canvasH = ideal < cap ? ideal : cap;
        final canvasW = canvasH * kPageAspectRatio;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Center(
                child: SizedBox(
                  width: canvasW,
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
            TabBar(
              controller: s._tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final t in kWriteTabs) Tab(text: t)],
            ),
            Expanded(
              child: TabBarView(
                controller: s._tab,
                children: [
                  _writeTab(context, ref),
                  _paperTab(),
                  _colorTab(),
                  _photoTab(),
                  _tapeTab(),
                  _stickerTab(),
                ],
              ),
            ),
          ],
        );
      },
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

  // ── 탭별 패널 ────────────────────────────────────────────────────────────

  /// 글쓰기 탭: 제목/날짜/기분/날씨/본문/태그/첨부/저장 등 모든 메타 편집.
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
        if (!s._isEditing && journal != null) ...[
          _JournalSelector(
            journal: journal,
            canSwitch: s._canSwitchJournal,
            onTap: s._canSwitchJournal ? () => s._pickJournal(journals) : null,
          ),
          _NewEntryOrdinal(journalId: jid),
          const SizedBox(height: 12),
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
        const SizedBox(height: 16),
        WeatherField(
          value: s._weather,
          onChanged: (w) => s.refresh(() => s._weather = w),
        ),
        const SizedBox(height: 16),
        // 본문은 여기서 쓰고, 위 캔버스에 그대로(WYSIWYG) 비친다.
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
          suggestions:
              extractHashtagSuggestions(s._contentCtrl.text, s._tags),
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
                    visibility:
                        s._editing?.visibility ?? EntryVisibility.private)
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

  Widget _paperTab() => _controlScroll(
        AnimatedBuilder(
          animation: s._deco,
          builder: (context, _) => PaperSelector(
            paper: s._deco.canvas.paper,
            paperColorValue: s._deco.canvas.paperColorValue,
            onPaperChanged: s._deco.setPaperStyle,
            onColorChanged: s._deco.setPaperColorValue,
            showColor: false,
          ),
        ),
      );

  Widget _colorTab() => _controlScroll(
        AnimatedBuilder(
          animation: s._deco,
          builder: (context, _) => PaperSelector(
            paper: s._deco.canvas.paper,
            paperColorValue: s._deco.canvas.paperColorValue,
            onPaperChanged: s._deco.setPaperStyle,
            onColorChanged: s._deco.setPaperColorValue,
            showPaper: false,
          ),
        ),
      );

  Widget _photoTab() => _controlScroll(
        Builder(
          builder: (context) => AnimatedBuilder(
            animation: s._deco,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Text('사진·글자를 얹고, 위 캔버스에서 끌어 옮기세요',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHint)),
                ),
                _decoPalette(
                  context,
                  showTape: false,
                  showSticker: false,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _tapeTab() => _controlScroll(
        AnimatedBuilder(
          animation: s._deco,
          builder: (context, _) => _decoPalette(
            context,
            showPhoto: false,
            showSticker: false,
          ),
        ),
      );

  Widget _stickerTab() => _controlScroll(
        AnimatedBuilder(
          animation: s._deco,
          builder: (context, _) => _decoPalette(
            context,
            showPhoto: false,
            showTape: false,
          ),
        ),
      );

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

  Widget _controlScroll(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: child,
      );
}
