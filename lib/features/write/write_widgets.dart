part of 'write_screen.dart';

/// Header chip showing the target journal. Tappable (with a ▾) when the
/// journal can be changed; otherwise a static label.
class _JournalSelector extends StatelessWidget {
  const _JournalSelector({
    required this.journal,
    required this.canSwitch,
    this.onTap,
  });
  final Journal journal;
  final bool canSwitch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(journal.coverColor);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(journal.displayIcon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('일기장 · ',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Flexible(
              child: Text(
                journal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            if (canSwitch) ...[
              const Spacer(),
              const Text('변경',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

/// Title input plus a one-tap suggestion chip. While the title is empty and
/// the body has a usable first line, tapping the chip fills the title with it
/// (via [suggestTitleFromContent]). Listens to its own controller so typing a
/// title hides the chip immediately.
class _TitleField extends StatefulWidget {
  const _TitleField({
    required this.controller,
    required this.contentText,
    required this.onApply,
  });
  final TextEditingController controller;
  final String contentText;
  final ValueChanged<String> onApply;

  @override
  State<_TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<_TitleField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = widget.controller.text.trim().isEmpty
        ? suggestTitleFromContent(widget.contentText)
        : null;
    final tooLong = isTitleTooLong(widget.controller.text);
    final echoesFirstLine =
        titleEchoesFirstLine(widget.controller.text, widget.contentText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: const InputDecoration(
            hintText: '제목 (선택)',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        if (suggestion != null)
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.title,
                  size: 16, color: AppColors.primary),
              label: Text(
                '제목으로: $suggestion',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () => widget.onApply(suggestion),
            ),
          ),
        if (tooLong)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '제목이 길어요 · 목록에서 잘릴 수 있어요',
              style: TextStyle(fontSize: 12, color: AppColors.moodHard),
            ),
          ),
        if (echoesFirstLine)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '제목이 본문 첫 줄과 같아요 · 본문 첫 줄은 지워도 돼요',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
      ],
    );
  }
}

/// Right-aligned meta below the content field: live char/word count, an
/// optional encouragement milestone, and a rough reading-time estimate once
/// the entry is long enough. All values come from pure helpers in
/// `text_stats.dart`.
class _ContentMeta extends StatelessWidget {
  const _ContentMeta(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = textStats(text);
    final milestone = writingMilestone(s.chars);
    final minutes = readingMinutes(s.chars);
    final sentences = countSentences(text);
    final paragraphs = countParagraphs(text);
    final questions = countQuestions(text);
    final avgSentence = averageSentenceLength(text);
    final avgWord = averageWordLength(text);
    final longestSentence = longestSentenceLength(text);
    final paragraphHint = paragraphBreakHint(s.chars, paragraphs);
    final longSentence = longSentenceHint(longestSentence);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '글자 ${s.chars} · 단어 ${s.words}'
            '${sentences > 0 ? ' · 문장 $sentences' : ''}'
            '${paragraphs > 1 ? ' · 문단 $paragraphs' : ''}'
            '${questions > 0 ? ' · 질문 $questions' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        if (avgSentence != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '📝 문장당 평균 $avgSentence자'
              '${avgWord != null ? ' · 단어당 $avgWord자' : ''}'
              '${longestSentence != null ? ' · 최장 문장 $longestSentence자' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
        if (minutes != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '📖 약 $minutes분 읽을 분량',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
        if (milestone != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              milestone,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
        if (paragraphHint != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              paragraphHint,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
        ],
        if (longSentence != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              longSentence,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
        ],
      ],
    );
  }
}

/// The entry's tag chips (each deletable) plus a gentle hint when there are a
/// lot of them (see [tagCountHint]). Renders nothing when there are no tags.
class _EntryTags extends StatelessWidget {
  const _EntryTags({required this.tags, required this.onRemove});
  final List<String> tags;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final hint = tagCountHint(tags.length);
    final lengthHint = longTagHint(tags);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final t in tags)
                Chip(label: Text('#$t'), onDeleted: () => onRemove(t)),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(hint,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ),
          if (lengthHint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(lengthHint,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ),
        ],
      ),
    );
  }
}

/// One-tap chips for `#hashtags` found in the body that aren't tags yet.
/// Tapping a chip adds that tag. Renders nothing when there is nothing to
/// suggest. Suggestions come from [extractHashtagSuggestions].
class _HashtagSuggestions extends StatelessWidget {
  const _HashtagSuggestions({required this.suggestions, required this.onAdd});
  final List<String> suggestions;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final t in suggestions)
            ActionChip(
              avatar:
                  const Icon(Icons.tag, size: 16, color: AppColors.primary),
              label: Text('#$t 추가'),
              onPressed: () => onAdd(t),
            ),
        ],
      ),
    );
  }
}

/// One-tap chips of the diary's most-used tags (from [availableTagsProvider],
/// frequency-ranked, replies excluded) that aren't on this entry yet. Tapping
/// adds the tag. Renders nothing when there is nothing left to suggest.
class _FrequentTagChips extends ConsumerWidget {
  const _FrequentTagChips({required this.current, required this.onAdd});
  final List<String> current;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions =
        frequentTagSuggestions(ref.watch(availableTagsProvider), current);
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('자주 쓰는 태그',
              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          for (final t in suggestions)
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text('#$t'),
              onPressed: () => onAdd(t),
            ),
        ],
      ),
    );
  }
}

/// While composing a *new* entry, a gentle nudge showing which number this
/// entry will be within its journal (e.g. "이 일기장의 7번째 기록이에요"). Watches
/// the entry list and computes the position via [nextEntryOrdinal] (replies
/// ignored). Shown only for new entries.
class _NewEntryOrdinal extends ConsumerWidget {
  const _NewEntryOrdinal({required this.journalId});
  final String journalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value;
    if (entries == null) return const SizedBox.shrink();
    final n = nextEntryOrdinal(entries, journalId);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, size: 15, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text('이 일기장의 $n번째 기록이에요',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

/// While composing a *new* entry, a gentle note when the chosen day already
/// holds records in this journal (e.g. a back-dated entry), via [entriesOnDate].
/// Renders nothing when the day is empty, so today's first entry stays quiet.
class _SameDayCount extends ConsumerWidget {
  const _SameDayCount({required this.journalId, required this.date});
  final String journalId;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider).asData?.value;
    if (entries == null) return const SizedBox.shrink();
    final n = entriesOnDate(entries, journalId, date);
    if (n == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.event_note, size: 15, color: AppColors.textHint),
          const SizedBox(width: 6),
          Text('이 날짜에 이미 $n개의 기록이 있어요',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

/// The row of attach actions under the editor (사진 / 음성 / 위치 / 태그). Voice is
/// not wired yet (disabled). Pulled out of the write screen to keep it small.
class _AttachRow extends StatelessWidget {
  const _AttachRow({
    required this.onPhoto,
    required this.onLocation,
    required this.onTag,
  });
  final VoidCallback onPhoto;
  final VoidCallback onLocation;
  final VoidCallback onTag;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _AttachButton(Icons.photo_outlined, '사진', onPhoto),
        const _AttachButton(Icons.mic_none, '음성', null),
        _AttachButton(Icons.place_outlined, '위치', onLocation),
        _AttachButton(Icons.tag, '태그', onTag),
      ],
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.textSecondary),
      label: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Entry point to the page-decoration canvas. Shows a read-only preview of the
/// saved canvas (if any) plus a button to open the editor. Tapping either the
/// preview or the button opens [PageDecoPlayground].
class _DecoratePageTile extends StatelessWidget {
  const _DecoratePageTile({required this.canvasJson, required this.onEdit});

  final String? canvasJson;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final canvas = decodePageCanvas(canvasJson);
    final decorated = canvas.layers.isNotEmpty || canvas.paper != PaperStyle.plain;
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
                child: PageCanvasView(canvas, stickerBaseSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
