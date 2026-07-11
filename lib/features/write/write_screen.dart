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
import '../decorate/page_deco_playground.dart';
import '../decorate/paper_page.dart';
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
    with _PhotoDecoState, _PageDecoState {
  final _picker = ImagePicker();
  Mood? _mood;
  Weather? _weather;
  String? _location;
  final List<String> _photoPaths = [];
  List<String> _tags = [];
  DiaryEntry? _editing;
  bool _prefilled = false;

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
        _pageCanvas = entry.pageCanvas;
        _flowPhotos = entry.flowPhotos;
        _prefilled = true;
      }
    }
  }

  @override
  void dispose() {
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
          pageCanvas: _pageCanvas,
          clearPageCanvas: _pageCanvas == null,
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
          pageCanvas: _pageCanvas,
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
    // Shared journals (커플/교환) default to shared; personal stays private-first.
    final journals =
        ref.watch(journalsProvider).asData?.value ?? const <Journal>[];
    final jid = _targetJournalId;
    final journal = journals.where((j) => j.journalId == jid).firstOrNull;
    final shared = journal != null && journal.type != JournalType.personal;
    final canSave = canSaveEntry(content: _contentCtrl.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '기록 수정' : '새 기록'),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: _confirmClose),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Shows (and, for new entries, lets you change) the target journal.
          if (!_isEditing && journal != null) ...[
            _JournalSelector(
              journal: journal,
              canSwitch: _canSwitchJournal,
              onTap: _canSwitchJournal
                  ? () => _pickJournal(journals)
                  : null,
            ),
            _NewEntryOrdinal(journalId: jid),
            const SizedBox(height: 12),
          ],
          _TitleField(
            controller: _titleCtrl,
            contentText: _contentCtrl.text,
            onApply: (t) {
              _titleCtrl.text = t;
              setState(() {});
            },
          ),
          const Divider(),
          DateField(date: _date, onTap: _pickDate),
          if (!_isEditing) _SameDayCount(journalId: jid, date: _date),
          const SizedBox(height: 8),
          MoodField(
            value: _mood,
            contentText: _contentCtrl.text,
            onChanged: (m) => setState(() => _mood = m),
          ),
          const SizedBox(height: 16),
          WeatherField(
            value: _weather,
            onChanged: (w) => setState(() => _weather = w),
          ),
          const SizedBox(height: 20),
          // 본문을 "종이 페이지" 위에 직접 쓴다(속지 무늬·바탕색을 아래에서 바로 고름).
          PaperPageBackground(
            canvas: _canvasModel,
            child: TextField(
              controller: _contentCtrl,
              minLines: 8,
              maxLines: null,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                  fontSize: 15, height: 1.6, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                isCollapsed: true,
                hintText: '오늘 어떤 하루였나요?',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          PaperSelector(
            paper: _canvasModel.paper,
            paperColorValue: _canvasModel.paperColorValue,
            onPaperChanged: _setPaperStyle,
            onColorChanged: _setPaperColorValue,
          ),
          const SizedBox(height: 6),
          _ContentMeta(_contentCtrl.text),
          if (_contentCtrl.text.trim().isEmpty) ...[
            const SizedBox(height: 12),
            WritingPromptCard(
              prompt: ref.watch(writingPromptProvider),
              onUse: () {
                final p = ref.read(writingPromptProvider);
                _contentCtrl.text = '$p\n';
                _contentCtrl.selection = TextSelection.collapsed(offset: _contentCtrl.text.length);
                setState(() {});
              },
              onRefresh: () =>
                  ref.read(writingPromptIndexProvider.notifier).next(),
            ),
          ],
          if ((_location ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                avatar: const Icon(Icons.place, size: 18),
                label: Text(_location!.trim()),
                onPressed: _editLocation,
                onDeleted: () => setState(() => _location = null),
              ),
            ),
          ],
          if (_photoPaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _PhotoThumbnailsRow(
              photoPaths: _photoPaths,
              photoFrames: _photoFrames,
              photoStickers: _photoStickers,
              photoTapes: _photoTapes,
              photoMemos: _photoMemos,
              photoAspects: _photoAspects,
              photoFilters: _photoFilters,
              photoCrops: _photoCrops,
              onRemove: (i) => setState(() {
                _photoPaths.removeAt(i);
                _removePhotoDecoAt(i);
              }),
              onFramePicked: (i, frameId) =>
                  setState(() => _setFrameAt(i, frameId)),
              onStickerPicked: (i, emoji) =>
                  setState(() => _setStickerAt(i, emoji)),
              onTapePicked: (i, tapeId) =>
                  setState(() => _setTapeAt(i, tapeId)),
              onMemoPicked: (i, memo) =>
                  setState(() => _setMemoAt(i, memo)),
              onAspectPicked: (i, aspectId) =>
                  setState(() => _setAspectAt(i, aspectId)),
              onFilterPicked: (i, filterId) =>
                  setState(() => _setFilterAt(i, filterId)),
              onCropPicked: (i, cropId) =>
                  setState(() => _setCropAt(i, cropId)),
            ),
          ],
          _EntryTags(
            tags: _tags,
            onRemove: (t) => setState(() => _tags.remove(t)),
          ),
          _HashtagSuggestions(
            suggestions: extractHashtagSuggestions(_contentCtrl.text, _tags),
            onAdd: _addTagDirect,
          ),
          _FrequentTagChips(current: _tags, onAdd: _addTagDirect),
          const SizedBox(height: 16),
          _AttachRow(
            onPhoto: _pickPhotos,
            onLocation: _editLocation,
            onTag: _addTag,
            onEmoji: () => pickAndInsertEmoji(context, _contentCtrl).then((_) => mounted ? setState(() {}) : null),
          ),
          const SizedBox(height: 16),
          _DecoratePageTile(canvasJson: _pageCanvas, content: _contentCtrl.text, onEdit: _editPageCanvas),
          // "본문 사이 사진"은 신규 진입을 숨김(대신 사진 캐러셀/장식으로 대체 예정).
          // 이미 사용된 기존 기록은 계속 수정할 수 있도록 데이터가 있을 때만 노출.
          if (decodeInlinePhotos(_flowPhotos).isNotEmpty) ...[
            const SizedBox(height: 12),
            InlinePhotoTile(flowPhotos: _flowPhotos, onEdit: _editInlinePhotos),
          ],
          const SizedBox(height: 28),
          if (_isEditing)
            ElevatedButton(
              onPressed: canSave
                  ? () => _save(
                        visibility:
                            _editing?.visibility ?? EntryVisibility.private,
                      )
                  : null,
              child: const Text('수정 저장'),
            )
          else if (shared) ...[
            // 커플/교환 일기장은 멤버와 함께 보는 공동 기록이 기본.
            ElevatedButton(
              onPressed:
                  canSave ? () => _save(visibility: EntryVisibility.link) : null,
              child: const Text('함께 저장'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: canSave
                  ? () => _save(visibility: EntryVisibility.private)
                  : null,
              child: const Text('비공개 저장'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed:
                  canSave ? () => _save(visibility: EntryVisibility.link) : null,
              child: const Text('공유하며 저장',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
