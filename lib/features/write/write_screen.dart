import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'emoji_picker.dart';
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

  /// 하단 탭(글쓰기/속지/바탕색/사진/테이프/스티커). 캔버스는 상단에 고정되고,
  /// 이 탭이 아래 컨트롤 패널과 캔버스의 레이어 편집 활성 여부를 바꾼다.
  late final TabController _tab =
      TabController(length: kWriteTabs.length, vsync: this)
        ..addListener(() {
          // 탭이 바뀌면 캔버스 상호작용(레이어 드래그) 여부가 달라지므로 다시 그린다.
          if (mounted) setState(() {});
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
    if (_isEditing && !_prefilled) {
      final entries = ref.read(entriesProvider).asData?.value ?? const [];
      final entry = entries.where((e) => e.entryId == widget.editId).firstOrNull;
      if (entry != null) {
        _editing = entry;
        _date = entry.createdAt;
        _titleCtrl.text = entry.title ?? '';
        _contentCtrl.text = entry.content;
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
        _prefilled = true;
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    _deco.dispose();
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
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
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
    if (_isEditing && _editing != null) {
      // Edit: keep id/createdAt; editEntry regenerates the AI summary.
      await notifier.editEntry(
        _editing!.copyWith(
          title: tidyEntryTitle(_titleCtrl.text),
          content: tidyEntryContent(_contentCtrl.text),
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
          mood: _mood,
          weather: _weather,
          visibility: visibility,
          location: _location,
          aiStatus: AiStatus.pending, // summary generated async (see TECH_DESIGN.md)
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
