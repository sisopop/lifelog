import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../decorate/aspect_picker_sheet.dart';
import '../decorate/content_flow.dart';
import '../decorate/crop_picker_sheet.dart';
import '../decorate/filter_picker_sheet.dart';
import '../decorate/frame_picker_sheet.dart';
import '../decorate/framed_photo.dart';
import '../decorate/inline_photo_editor.dart';
import '../decorate/memo_dialog.dart';
import '../decorate/page_canvas.dart';
import '../decorate/page_canvas_view.dart';
import '../decorate/page_deco_editor.dart';
import '../decorate/page_deco_palette.dart';
import '../decorate/paper_selector.dart';
import '../decorate/photo_frames.dart';
import '../decorate/photo_aspects.dart';
import '../decorate/photo_crops.dart';
import '../decorate/photo_filters.dart';
import '../decorate/photo_memos.dart';
import '../decorate/photo_stickers.dart';
import '../decorate/photo_tapes.dart';
import '../decorate/sticker_picker_sheet.dart';
import '../decorate/tape_picker_sheet.dart';
import '../decorate/text_layer_dialog.dart';
import 'body_rich_editor.dart';
import 'emoji_picker.dart';
import '../decorate/textbox_rich_editor.dart';
import '../../shared/models/diary_entry.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/photo.dart';
import '../../shared/models/journal.dart';
import '../entries/entries_provider.dart';
import '../entry_detail/entry_neighbors.dart';
import '../journals/journal_repository.dart';
import '../tags/tag_suggest.dart';
import '../timeline/timeline_filter.dart';
import 'date_field.dart';
import 'decor_sheet.dart';
import 'draft_guard.dart';
import 'journal_picker_sheet.dart';
import 'entry_date.dart';
import 'location_field.dart';
import 'mood_field.dart';
import 'tag_input_sheet.dart';
import 'text_stats.dart';
import 'weather_field.dart';
import 'writing_prompt_card.dart';
import 'writing_prompts.dart';
import '../journals/journals_provider.dart';
import '../journals/turn_provider.dart';

part 'write_widgets.dart';
part 'write_deco_tile.dart';
part 'write_photo_row.dart';
part 'write_photo_deco.dart';
part 'write_canvas_tabs.dart';

class WriteScreen extends ConsumerStatefulWidget {
  const WriteScreen({
    super.key,
    this.editId,
    this.journalId,
    this.authorId,
    this.advanceTurn = false,
    this.initialDate,
  });

  /// When set, the screen edits an existing entry instead of creating one.
  final String? editId;

  /// Target journal for a new entry. Defaults to the user's default journal.
  final String? journalId;

  /// Who the new entry is attributed to (교환일기 차례 멤버). Defaults to 'me'.
  final String? authorId;

  /// After saving, advance the exchange-journal turn to the next member.
  final bool advanceTurn;

  /// Pre-selects a calendar day for a new entry. Ignored when editing.
  final DateTime? initialDate;

  @override
  ConsumerState<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends ConsumerState<WriteScreen>
    with _PhotoDecoState, _PageDecoState, SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  Mood? _mood;
  Weather? _weather;
  String? _location;
  final List<String> _photoPaths = [];
  List<String> _tags = [];
  DiaryEntry? _editing;
  bool _prefilled = false;

  /// 본문 리치텍스트 편집기(flutter_quill)의 컨트롤러. 프리필·저장·이모지/프롬프트
  /// 삽입을 위해 화면이 직접 들고, [BodyRichEditor]가 이를 구독해 그린다. 값이 바뀌면
  /// [_onBodyChanged]가 평문을 [_contentCtrl]에 미러링해 검색·통계·미리보기가 계속
  /// 동작한다. didChangeDependencies에서 한 번만 만든다.
  QuillController? _bodyQuill;

  /// 상단 2개 탭(글쓰기/꾸미기). 글쓰기 탭은 메타+본문, 꾸미기 탭은 미리보기
  /// 캔버스 + 하위 5탭(속지/바탕색/사진/테이프/스티커)을 담는다.
  late final TabController _tab =
      TabController(length: kWriteTabs.length, vsync: this)
        ..addListener(() {
          if (!mounted) return;
          // 탭이 실제로 바뀔 때 자판을 내린다. 안 그러면 글쓰기 본문 TextField가
          // 포커스를 쥔 채 꾸미기로 넘어와, 자판 입력이 계속 본문을 편집해
          // 꾸미기에서 글이 추가·삭제되는 것처럼 보이는 버그가 생긴다.
          if (_tab.indexIsChanging) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
          // 탭이 바뀌면 다시 그린다(꾸미기 탭 캔버스가 최신 본문을 반영하도록).
          setState(() {});
        });

  /// Selected calendar day (date part only; time-of-day preserved on save).
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (!_isEditing && widget.initialDate != null) {
      _date = widget.initialDate!;
    }
  }

  /// Target journal for a new entry; changeable via the selector at the top.
  String? _journalId;

  bool get _isEditing => widget.editId != null;

  /// 탭 패널(별도 위젯 _WriteCanvasBody)에서 상태를 바꾼 뒤 다시 그리게 하는
  /// 공개 래퍼. setState가 protected라 외부 클래스에서 직접 못 부르기 때문.
  void refresh(VoidCallback fn) => setState(fn);

  /// Editing keeps the entry's journal; exchange-turn writes are pinned.
  bool get _canSwitchJournal => !_isEditing && !widget.advanceTurn;

  String get _targetJournalId =>
      _journalId ?? widget.journalId ?? JournalRepository.defaultJournalId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    var plain = '';
    String? rich;
    if (_isEditing) {
      final entries = ref.read(entriesProvider).asData?.value ?? const [];
      final entry = entries.where((e) => e.entryId == widget.editId).firstOrNull;
      // 아직 목록 로드 전이면 컨트롤러를 만들지 말고 다음 프레임에 재시도한다.
      if (entry == null) return;
      _editing = entry;
      _date = entry.createdAt;
      _titleCtrl.text = entry.title ?? '';
      plain = entry.content;
      rich = entry.contentRich;
      _mood = entry.mood;
      _weather = entry.weather;
      _location = entry.location;
      _photoPaths
        ..clear()
        ..addAll(entry.mediaUrls);
      _prefillPhotoDeco(entry);
      _tags
        ..clear()
        ..addAll(entry.tags);
      _deco.load(decodePageCanvas(entry.pageCanvas));
      _flowPhotos = entry.flowPhotos;
    }
    _contentCtrl.text = plain; // 검색·통계·미리보기용 평문 미러
    _bodyQuill = QuillController(
      document: buildTextBoxQuillDocument(rich, plain),
      selection: const TextSelection.collapsed(offset: 0),
    )..addListener(_onBodyChanged);
    _prefilled = true;
  }

  /// 본문 편집기가 바뀔 때마다 평문을 [_contentCtrl]에 미러링하고 화면을 갱신한다.
  void _onBodyChanged() {
    final q = _bodyQuill;
    if (q == null) return;
    final plain = q.document.toPlainText().replaceAll(RegExp(r'\n$'), '');
    if (plain != _contentCtrl.text) _contentCtrl.text = plain;
    if (mounted) setState(() {});
  }

  /// 저장할 본문 리치텍스트(Quill Delta JSON). 본문이 비면 null(서식도 없음).
  String? get _bodyRichJson {
    final q = _bodyQuill;
    if (q == null) return null;
    if (q.document.toPlainText().trim().isEmpty) return null;
    return jsonEncode(q.document.toDelta().toJson());
  }

  /// 이모지 픽커를 열고 고른 이모지를 본문 편집기의 현재 커서 위치에 끼운다.
  Future<void> insertBodyEmoji(BuildContext context) async {
    final emoji = await pickEmoji(context);
    final q = _bodyQuill;
    if (emoji == null || q == null) return;
    final sel = q.selection;
    final at = sel.isValid ? sel.baseOffset : (q.document.length - 1);
    q.replaceText(at, sel.isValid ? (sel.extentOffset - sel.baseOffset).abs() : 0,
        emoji, TextSelection.collapsed(offset: at + emoji.length));
  }

  /// 글쓰기 프롬프트 문구로 본문을 채운다(본문이 비었을 때만 노출되는 카드).
  void applyBodyPrompt(String prompt) {
    final q = _bodyQuill;
    if (q == null) return;
    final text = '$prompt\n';
    q.replaceText(0, q.document.length - 1, text,
        TextSelection.collapsed(offset: text.length));
  }

  @override
  void dispose() {
    _tab.dispose();
    _deco.dispose();
    _bodyQuill?.removeListener(_onBodyChanged);
    _bodyQuill?.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      // base64 data URLs so photos persist in the DB (see shared/widgets/photo.dart).
      final encoded = <String>[];
      for (final x in picked) {
        final bytes = await x.readAsBytes();
        encoded.add(
            'data:${imageMimeForName(x.name)};base64,${base64Encode(bytes)}');
      }
      if (mounted) setState(() => _photoPaths.addAll(encoded));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러오지 못했어요')),
        );
      }
    }
  }

  Future<void> _addTag() async {
    final tag = await showTagInputSheet(
      context: context,
      allTags: ref.read(availableTagsProvider),
      exclude: _tags,
    );
    if (tag != null && tag.isNotEmpty) {
      setState(() => _tags = withTagsAdded(_tags, tag));
    }
  }

  void _addTagDirect(String tag) {
    setState(() => _tags = withTagAdded(_tags, tag));
  }

  /// Back-date the entry. Future dates are disallowed (it's a diary).
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Attach/edit a place name (no GPS); offers chips for places used before.
  Future<void> _editLocation() async {
    final result = await showLocationDialog(
      context: context,
      allLocations: ref.read(availableLocationsProvider),
      current: _location,
    );
    if (result == null) return; // dismissed
    // 여러 곳을 쉼표로 넣으면 대표 장소 1개만 location, 나머지는 태그로 저장(approach B).
    final split = splitPlaceInput(result);
    setState(() {
      _location = split.location;
      for (final place in split.extraPlaces) {
        _tags = withTagAdded(_tags, place);
      }
    });
  }

  Future<void> _save({required EntryVisibility visibility}) async {
    // 본문이 비어도 꾸미기 캔버스에 내용이 있으면 저장을 허용한다(캔버스
    // 텍스트박스에만 쓴 글도 기록으로 남고 검색된다). 둘 다 비면 막는다.
    if (_contentCtrl.text.trim().isEmpty && _deco.isBlank) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력하거나 꾸미기를 추가해주세요')),
      );
      return;
    }
    final now = DateTime.now();
    final notifier = ref.read(entriesProvider.notifier);
    final frames = encodePhotoFrames(_photoFrames);
    final stickers = encodePhotoStickers(_photoStickers);
    final tapes = encodePhotoTapes(_photoTapes);
    final memos = encodePhotoMemos(_photoMemos);
    final aspects = encodePhotoAspects(_photoAspects);
    final filters = encodePhotoFilters(_photoFilters);
    final crops = encodePhotoCrops(_photoCrops);
    final pageCanvas = _pageCanvasJson;
    final contentRich = _bodyRichJson;
    if (_isEditing && _editing != null) {
      // Edit: keep id/createdAt; editEntry regenerates the AI summary.
      await notifier.editEntry(
        _editing!.copyWith(
          title: tidyEntryTitle(_titleCtrl.text),
          content: tidyEntryContent(_contentCtrl.text),
          contentRich: contentRich,
          clearContentRich: contentRich == null,
          mood: _mood,
          weather: _weather,
          clearWeather: _weather == null,
          visibility: visibility,
          // '' (not null) so clearing the place persists (copyWith ignores null).
          location: _location ?? '',
          mediaUrls: List.of(_photoPaths),
          tags: tidyTags(_tags),
          pageCanvas: pageCanvas,
          clearPageCanvas: pageCanvas == null,
          flowPhotos: _flowPhotos,
          clearFlowPhotos: _flowPhotos == null,
          photoFrames: frames,
          clearPhotoFrames: frames == null,
          photoStickers: stickers,
          clearPhotoStickers: stickers == null,
          photoTapes: tapes,
          clearPhotoTapes: tapes == null,
          photoMemos: memos,
          clearPhotoMemos: memos == null,
          photoAspects: aspects,
          clearPhotoAspects: aspects == null,
          photoFilters: filters,
          clearPhotoFilters: filters == null,
          photoCrops: crops,
          clearPhotoCrops: crops == null,
          createdAt: composeEntryDate(_date, _editing!.createdAt),
        ),
      );
    } else {
      final journalId = _targetJournalId;
      await notifier.add(
        DiaryEntry(
          entryId: now.microsecondsSinceEpoch.toString(),
          userId: widget.authorId ?? 'me',
          journalId: journalId,
          title: tidyEntryTitle(_titleCtrl.text),
          content: tidyEntryContent(_contentCtrl.text),
          contentRich: contentRich,
          mood: _mood,
          weather: _weather,
          visibility: visibility,
          location: _location,
          // 본문이 있으면 요약 대기, 없으면(캔버스만) 요약할 게 없어 none.
          aiStatus: _contentCtrl.text.trim().isEmpty
              ? AiStatus.none
              : AiStatus.pending, // summary generated async (see TECH_DESIGN.md)
          mediaUrls: List.of(_photoPaths),
          tags: tidyTags(_tags),
          pageCanvas: pageCanvas,
          flowPhotos: _flowPhotos,
          photoFrames: frames,
          photoStickers: stickers,
          photoTapes: tapes,
          photoMemos: memos,
          photoAspects: aspects,
          photoFilters: filters,
          photoCrops: crops,
          createdAt: composeEntryDate(_date, now),
          updatedAt: now,
        ),
      );
      // 교환일기: 기록 후 다음 멤버에게 차례를 넘긴다.
      if (widget.advanceTurn) {
        await ref.read(exchangeTurnControllerProvider).advance(journalId);
      }
    }
    if (mounted) context.pop();
  }

  /// Closes the writer, asking first if a new draft would be thrown away.
  Future<void> _confirmClose() async {
    if (!hasUnsavedDraft(
      isEditing: _isEditing,
      title: _titleCtrl.text,
      content: _contentCtrl.text,
      hasCanvas: !_deco.isBlank,
    )) {
      context.pop();
      return;
    }
    if (await confirmLeaveDraft(context) && mounted) context.pop();
  }

  /// Bottom sheet to change which journal this new entry is saved into.
  Future<void> _pickJournal(List<Journal> journals) async {
    final picked = await showJournalPicker(
      context: context,
      journals: journals,
      currentId: _targetJournalId,
    );
    if (picked != null && picked != _targetJournalId) {
      setState(() => _journalId = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 물리 back key도 X(닫기) 버튼과 똑같이 초안 폐기 확인을 거치게 한다.
    // canPop:false로 시스템 pop을 막고, 확인 다이얼로그를 통과한 경우에만
    // _confirmClose가 직접 pop 한다(초안 없으면 바로 닫힘).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? '기록 수정' : '새 기록'),
          leading: IconButton(
              icon: const Icon(Icons.close), onPressed: _confirmClose),
        ),
        // 캔버스(세로 3:4)를 상단에 고정하고, 하단에 탭바 + 탭별 컨트롤 패널을 둔다.
        body: _WriteCanvasBody(this),
      ),
    );
  }
}
