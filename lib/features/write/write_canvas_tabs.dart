part of 'write_screen.dart';

/// 글쓰기 화면 **상단** 탭 라벨. 글쓰기 / 꾸미기 2개.
const List<String> kWriteTabs = ['글쓰기', '꾸미기'];

/// 꾸미기 탭 **안쪽** 하위 탭 라벨. 속지 / 바탕색 / 사진 / 테이프 / 스티커 / 텍스트 6개.
const List<String> kDecorSubTabs = ['속지', '바탕색', '사진', '테이프', '스티커', '텍스트'];

/// 글쓰기 화면 본문.
///
/// 구조: 상단 [TabBar](글쓰기/꾸미기) + [TabBarView].
///   - 글쓰기 탭: 메타(저널/제목/날짜/감정/날씨) + 본문 입력 + 프롬프트 + 태그 + 첨부 + 저장.
///   - 꾸미기 탭: 상단 고정 미리보기 캔버스(레이어 드래그) + 그 아래 **하위 TabBar**
///     (속지/바탕색/사진/테이프/스티커/텍스트) + 각 탭의 컨트롤.
///
/// 꾸미기 캔버스는 스크롤 밖에 고정해, 아래 컨트롤 스크롤이 스티커 드래그를
/// 가로채지 않게 한다. 본문(글쓰기 탭)을 바꾸면 캔버스에 WYSIWYG로 비친다.
///
/// 상태는 모두 [_WriteScreenState] `s`가 소유하고, 이 위젯은 그것을 읽어 그린다.
/// (하위 6탭은 [DefaultTabController]로 관리해 write_screen의 TabController는
/// 상단 2탭만 담당한다.)
class _WriteCanvasBody extends ConsumerWidget {
  const _WriteCanvasBody(this.s);

  final _WriteScreenState s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TabBar(
          controller: s._tab,
          tabs: [for (final t in kWriteTabs) Tab(text: t)],
        ),
        Expanded(
          child: TabBarView(
            controller: s._tab,
            // 좌우 스와이프로 탭이 넘어가면 꾸미기 캔버스의 레이어 드래그(이동·
            // 확대축소·회전) 제스처를 가로채 조작이 방해된다. 스와이프 전환을 끄고
            // 탭 전환은 상단 탭 라벨 탭으로만 하게 한다.
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _writeTab(context, ref),
              _decorateTab(context),
            ],
          ),
        ),
      ],
    );
  }

  // ── 글쓰기 탭 상단 메타(저널/제목/날짜/감정/날씨) ────────────────────────────
  // ListView 자식으로 쓰이므로 가로 여백은 바깥 ListView가 준다(자체 Padding 없음).

  Widget _metaHeader(BuildContext context, WidgetRef ref) {
    final journals =
        ref.watch(journalsProvider).asData?.value ?? const <Journal>[];
    final jid = s._targetJournalId;
    final journal = journals.where((j) => j.journalId == jid).firstOrNull;
    return Column(
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
        const Divider(height: 24),
      ],
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

  // ── 글쓰기 탭: 메타 + 본문 입력 + 프롬프트 + 태그 + 첨부 + 저장 ──────────────

  Widget _writeTab(BuildContext context, WidgetRef ref) {
    final journals =
        ref.watch(journalsProvider).asData?.value ?? const <Journal>[];
    final jid = s._targetJournalId;
    final journal = journals.where((j) => j.journalId == jid).firstOrNull;
    final shared = journal != null && journal.type != JournalType.personal;
    final canSave = canSaveEntry(
        content: s._contentCtrl.text, hasCanvas: !s._deco.isBlank);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // 상단 메타(저널/제목/날짜/감정/날씨).
        _metaHeader(context, ref),
        // 본문: 리치텍스트 인라인 편집기(글 선택 시 키보드 위 서식바). 평문은
        // _contentCtrl에 미러링돼 꾸미기 탭 캔버스에 실시간으로 비친다(WYSIWYG).
        if (s._bodyQuill != null)
          BodyRichEditor(controller: s._bodyQuill!)
        else
          const SizedBox(
            height: 156,
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 6),
        _ContentMeta(s._contentCtrl.text),
        if (s._contentCtrl.text.trim().isEmpty) ...[
          const SizedBox(height: 12),
          WritingPromptCard(
            prompt: ref.watch(writingPromptProvider),
            onUse: () {
              s.applyBodyPrompt(ref.read(writingPromptProvider));
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
          onEmoji: () => s
              .insertBodyEmoji(context)
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

  // ── 꾸미기 탭: 상단 고정 캔버스 + 하위 6탭(속지/바탕색/사진/테이프/스티커/텍스트) ─

  /// 꾸미기 탭 전체. 상단에 미리보기 캔버스를 고정하고, 그 위에 **드래그로 높이가
  /// 조절되는 하단 시트**([_DecorSheet])를 오버레이로 얹는다. 시트 안에는 하위 TabBar
  /// (속지/바탕색/사진/테이프/스티커/텍스트)와 각 탭의 컨트롤이 들어간다.
  ///
  /// 시트를 아래로 끌어 접으면 캔버스가 넓게 드러나고(접힌 상태에서도 캔버스 조작 가능),
  /// 위로 끌면 컨트롤(스티커 격자 등)이 넉넉히 보인다. 캔버스는 시트 **아래**(Stack의
  /// 먼저 그린 자식)라 시트가 가리는 부분 외에는 레이어 드래그가 그대로 먹는다.
  ///
  /// 높이 계산은 `box.maxHeight`에 키보드 인셋을 더해(=키보드 무관 안정 높이) 하므로,
  /// 텍스트박스를 인라인 편집하느라 키보드가 떠도 캔버스·상자가 납작해지지 않는다.
  Widget _decorateTab(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // 키보드 높이. Scaffold(resizeToAvoidBottomInset)가 body에 넘겨주는
        // MediaQuery는 bottom inset을 이미 소비해 0으로 보이므로, FlutterView에서
        // 직접 물리 inset(논리 px)을 읽는다. 키보드가 뜨면 box.maxHeight가 그만큼
        // 줄어드는데, 여기에 kb를 더해 키보드와 무관한 원래 높이(stableH)를 복원한다.
        final kb = MediaQueryData.fromView(View.of(context)).viewInsets.bottom;
        final stableH = box.maxHeight + kb; // 키보드와 무관한 안정 높이
        final fullWidth = box.maxWidth - 32; // 좌우 16 여백
        // 캔버스는 항상 가로 100%(폭 고정). 읽기(PageCanvasView·DecoratedPageView)
        // 와 같은 3:4 세로 높이(폭/0.75)를 그대로 준다 → 상자가 정확히 3:4라
        // WYSIWYG 유지. 세로 공간이 모자라도 **폭을 줄이지 않는다**(예전에 여기서
        // 폭을 줄여 캔버스가 작아지는 문제가 반복됨). 화면이 짧아 아래가 넘치면
        // 그 부분은 하단 드래그 시트가 덮고, 시트를 내리면 캔버스가 드러난다.
        final canvasH = fullWidth / kPageAspectRatio;
        final sheetMax = (stableH - 24).clamp(120.0, stableH).toDouble();
        const sheetMin = 96.0;
        final sheetInit =
            (stableH * 0.4).clamp(sheetMin, sheetMax).toDouble();
        return Stack(
          children: [
            // 상단 고정 미리보기 캔버스(레이어 드래그 가능). Stack의 먼저 그린 자식이라
            // 시트가 가리는 아래쪽 외에는 드래그가 그대로 먹는다.
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              height: canvasH,
              // 폭 고정(fullWidth) + 3:4 세로 높이(canvasH=폭/0.75)라 이 상자는
              // 이미 정확히 3:4 → PageDecoCanvas가 그대로 꽉 채우면 읽기(상세/카드)
              // 와 동일 좌표계가 된다(WYSIWYG). 비율 재강제(AspectRatio) 불필요.
              //
              // 텍스트박스를 인라인 편집해 자판이 떠 있으면(kb>0), 캔버스를 위로
              // 밀어 편집 중인 상자를 자판 위 남은 공간 가운데로 올린다(상자가
              // 자판에 가려 글이 안 보이는 문제). 자판을 내리면 밀기 0 → 원래 캔버스.
              child: AnimatedBuilder(
                animation: s._deco,
                builder: (context, _) {
                  final sel = s._deco.selected;
                  final shift =
                      (kb > 0 && sel != null && sel.kind == DecoKind.textbox)
                          ? decorCanvasEditShift(
                              canvasTop: 8,
                              canvasHeight: canvasH,
                              boxCenterY: sel.y,
                              viewportHeight: box.maxHeight,
                            )
                          : 0.0;
                  return Transform.translate(
                    offset: Offset(0, -shift),
                    child: PageDecoCanvas(
                      controller: s._deco,
                      titleText: s._titleCtrl.text,
                      contentText: s._contentCtrl.text,
                      interactive: true,
                    ),
                  );
                },
              ),
            ),
            // 드래그로 높이 조절되는 하단 컨트롤 시트. 텍스트박스를 인라인 편집하느라
            // 키보드가 떠 있을 때(kb>0)는 시트를 숨겨, 위 캔버스의 편집 중인 상자가
            // 키보드 위로 드러나게 한다(시트가 가리지 않도록).
            if (kb == 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecorSheet(
                minHeight: sheetMin,
                maxHeight: sheetMax,
                initialHeight: sheetInit,
                child: DefaultTabController(
                  length: kDecorSubTabs.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        tabs: [for (final t in kDecorSubTabs) Tab(text: t)],
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _decorPanel(() => _paperControls()), // 속지
                            _decorPanel(() => _colorControls()), // 바탕색
                            _decorPanel(() => _photoControls(context)), // 사진
                            _decorPanel(() => _tapeControls(context)), // 테이프
                            _decorPanel(
                                () => _stickerControls(context)), // 스티커
                            _decorPanel(() => _textControls(context)), // 텍스트
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 하위 탭 한 칸의 컨트롤 패널.
  ///
  /// [controls]는 **빌더 함수**로 받는다: AnimatedBuilder 안에서 매번 build 해야
  /// PaperSelector/DecoPalette가 컨트롤러 최신값(선택 칩 하이라이트 등)을 반영한다.
  /// 미리 만든 위젯을 넘기면 최초 빌드값에 고정돼 갱신되지 않는다(5bde29a 교훈).
  Widget _decorPanel(Widget Function() controls) => AnimatedBuilder(
        animation: s._deco,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: controls(),
        ),
      );

  // ── 탭별 컨트롤(속지/바탕색/사진/테이프/스티커/텍스트) ─────────────────────

  Widget _paperControls() => PaperSelector(
        paper: s._deco.canvas.paper,
        paperColorValue: s._deco.canvas.paperColorValue,
        onPaperChanged: s._deco.setPaperStyle,
        onColorChanged: s._deco.setPaperColorValue,
        showColor: false,
      );

  Widget _colorControls() => PaperSelector(
        paper: s._deco.canvas.paper,
        paperColorValue: s._deco.canvas.paperColorValue,
        onPaperChanged: s._deco.setPaperStyle,
        onColorChanged: s._deco.setPaperColorValue,
        showPaper: false,
      );

  /// 사진 탭: 사진 추가 버튼만 노출한다(글자는 텍스트 탭으로 이동).
  Widget _photoControls(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text('사진을 얹고, 위 미리보기에서 끌어 옮기세요',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
          _decoPalette(context,
              showText: false, showTape: false, showSticker: false),
        ],
      );

  Widget _tapeControls(BuildContext context) => _decoPalette(context,
      showPhoto: false, showText: false, showSticker: false);

  Widget _stickerControls(BuildContext context) =>
      _decoPalette(context, showPhoto: false, showText: false, showTape: false);

  /// 텍스트 탭: **글자 넣기**(기존 다이얼로그)와 **텍스트박스**(직접 입력하는 상자)
  /// 두 버튼을 노출한다.
  Widget _textControls(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
                '글자 넣기: 미리 꾸민 글 · 텍스트박스: 상자를 놓고 그 안에 직접 입력',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
          _decoPalette(context,
              showPhoto: false,
              showTape: false,
              showSticker: false,
              showTextBox: true),
        ],
      );

  Widget _decoPalette(
    BuildContext context, {
    bool showPhoto = true,
    bool showText = true,
    bool showTape = true,
    bool showSticker = true,
    bool showTextBox = false,
  }) {
    return DecoPalette(
      categoryIndex: s._deco.categoryIndex,
      onCategory: s._deco.setCategory,
      onAddPhoto: () => _addCanvasPhoto(context),
      onAddText: () => _addCanvasText(context),
      onAddTape: s._deco.addTape,
      onAddSticker: s._deco.addSticker,
      onAddTextBox: s._deco.addTextBox,
      showPhoto: showPhoto,
      showText: showText,
      showTape: showTape,
      showSticker: showSticker,
      showTextBox: showTextBox,
    );
  }
}
