import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/models/journal.dart';
import '../journals/journals_provider.dart';
import 'cover_band.dart';
import 'cover_binding.dart';
import 'cover_clip.dart';
import 'cover_corner.dart';
import 'cover_font.dart';
import 'cover_palette.dart';
import 'cover_paper.dart';
import 'cover_paper_color.dart';
import 'cover_paper_painter.dart';
import 'cover_pattern.dart';
import 'cover_ribbon.dart';
import 'cover_tab.dart';
import 'cover_texture.dart';
import 'cover_theme.dart';
import 'journal_cover.dart';

part 'cover_decorate_sections.dart';
part 'cover_decorate_layers.dart';

/// 미리보기 표지 크기. 드래그 좌표를 0~1 비율로 환산할 때 분모로 쓴다.
const double _kPreviewW = 110;
const double _kPreviewH = 140;

/// "꾸미기" 바텀시트를 엽니다 — 일기장 표지 꾸미기.
/// 책장에서 일기장을 길게 눌러 진입합니다. 칩을 탭하면 미리보기에 바로 보이고,
/// 우측 상단 "저장"을 눌러야 실제로 반영·저장됩니다(안 누르고 내리면 취소).
/// 섹션 빌더(칩 목록)는 분량이 커서 cover_decorate_sections.dart(part)로 분리.
Future<void> showCoverDecorateSheet(
  BuildContext context,
  WidgetRef ref,
  Journal journal,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CoverDecorateSheet(journal: journal),
  );
}

class _CoverDecorateSheet extends ConsumerStatefulWidget {
  const _CoverDecorateSheet({required this.journal});
  final Journal journal;

  @override
  ConsumerState<_CoverDecorateSheet> createState() => _CoverDecorateSheetState();
}

class _CoverDecorateSheetState extends ConsumerState<_CoverDecorateSheet> {
  late int _color = widget.journal.coverColor;
  late String _icon = widget.journal.displayIcon;
  // 표지 아이콘 자유 위치(0~1 비율). 미리보기를 끌어 옮긴다.
  late double _iconX = widget.journal.iconX;
  late double _iconY = widget.journal.iconY;
  late final String _pattern =
      normalizeCoverPattern(widget.journal.coverPattern);
  late String _binding = normalizeCoverBinding(widget.journal.coverBinding);
  late String _corner = normalizeCoverCorner(widget.journal.coverCorner);
  late String _band = normalizeCoverBand(widget.journal.coverBand);
  late String _ribbon = normalizeCoverRibbon(widget.journal.coverRibbon);
  late String _clip = normalizeCoverClip(widget.journal.coverClip);
  late String _tab = normalizeCoverTab(widget.journal.coverTab);
  late String _texture = normalizeCoverTexture(widget.journal.coverTexture);
  late String _font = normalizeCoverFont(widget.journal.coverFont);
  late String _paper = normalizeCoverPaper(widget.journal.innerPaper);
  late String _paperColor =
      normalizePaperColor(widget.journal.innerPaperColor);

  // 일기장 이름(제목). 표지 꾸미기 첫 섹션의 입력칸과 묶이고, 미리보기 표지에
  // 실시간으로 반영된다. 빈 값으로 저장하면 원래 이름을 유지한다.
  late final TextEditingController _titleCtrl =
      TextEditingController(text: widget.journal.title);
  late String _title = widget.journal.title;

  // 미리보기 캐러셀: 0=표지, 1=속지. 좌우로 드래그(또는 탭)해 전환한다.
  final _previewCtrl = PageController();
  int _previewPage = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _previewCtrl.dispose();
    super.dispose();
  }

  // Chip taps only update the live preview (local state). Nothing is written
  // to the DB until "저장" is tapped — this batches every change into a single
  // edit() and avoids per-tap async writes racing on web.
  void _pick(int c) => setState(() => _color = c);
  void _pickIcon(String e) => setState(() => _icon = e);
  void _pickBinding(String b) => setState(() => _binding = b);
  void _pickCorner(String c) => setState(() => _corner = c);
  void _pickBand(String b) => setState(() => _band = b);
  void _pickRibbon(String r) => setState(() => _ribbon = r);
  void _pickClip(String c) => setState(() => _clip = c);
  void _pickTab(String t) => setState(() => _tab = t);
  void _pickTexture(String t) => setState(() => _texture = t);
  void _pickFont(String f) => setState(() => _font = f);
  void _pickPaper(String p) => setState(() => _paper = p);
  void _pickPaperColor(String c) => setState(() => _paperColor = c);
  void _onTitleChanged(String v) => setState(() => _title = v);

  // 진짜 스티커처럼: 아이콘을 '집어서' 손가락 이동량만큼만 옮긴다(점프 없음).
  // 아이콘에서 먼 곳을 누르면 무시 → 잘못 눌러 순간이동하는 일이 없다.
  bool _draggingIcon = false;

  // 미리보기 표지 패딩(JournalCover 기본값과 동일) + 아이콘 글리프 추정 크기.
  // 아이콘이 움직일 수 있는 실제 영역(travel)과 현재 중심 계산에 쓴다.
  static const double _kPad = 12; // L/T/B (R은 10이지만 계산엔 영향 미미)
  static const double _kIconBox = 34; // iconSize 30 글리프 박스 근사

  double get _iconTravelX => _kPreviewW - _kPad - 10 - _kIconBox; // ≈54
  double get _iconTravelY => _kPreviewH - _kPad - _kPad - _kIconBox; // ≈82

  // 현재 아이콘 중심(미리보기 박스 local 좌표). grab 판정에 쓴다.
  Offset _iconCenterLocal() => Offset(
        _kPad + _iconX.clamp(0.0, 1.0) * _iconTravelX + _kIconBox / 2,
        _kPad + _iconY.clamp(0.0, 1.0) * _iconTravelY + _kIconBox / 2,
      );

  void _onIconPanStart(DragStartDetails d) {
    if (_icon == kNoCoverIcon) {
      _draggingIcon = false;
      return;
    }
    // 누른 지점이 아이콘 근처(넉넉한 반경)일 때만 잡기 시작.
    _draggingIcon =
        (d.localPosition - _iconCenterLocal()).distance <= _kIconBox;
  }

  void _onIconPanUpdate(DragUpdateDetails d) {
    if (!_draggingIcon) return;
    setState(() {
      _iconX = (_iconX + d.delta.dx / _iconTravelX).clamp(0.0, 1.0);
      _iconY = (_iconY + d.delta.dy / _iconTravelY).clamp(0.0, 1.0);
    });
  }

  void _onIconPanEnd(DragEndDetails d) => _draggingIcon = false;

  void _pickTheme(CoverTheme theme) {
    setState(() {
      _color = theme.color;
      _icon = theme.icon;
      _texture = theme.texture;
      _binding = theme.binding;
      _corner = theme.corner;
      _band = theme.band;
      _ribbon = theme.ribbon;
      _clip = theme.clip;
      _tab = theme.tab;
    });
  }

  /// Persist every layer at once, then close. Capturing the messenger before
  /// popping avoids using a deactivated context.
  void _save() {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // 이름은 공백을 다듬고, 비우면 원래 이름을 유지한다.
    final trimmed = _title.trim();
    final newTitle = trimmed.isEmpty ? widget.journal.title : trimmed;
    ref.read(journalsProvider.notifier).edit(
          widget.journal.copyWith(
            title: newTitle,
            coverColor: _color,
            icon: _icon,
            coverPattern: _pattern,
            coverBinding: _binding,
            coverCorner: _corner,
            coverBand: _band,
            coverRibbon: _ribbon,
            coverClip: _clip,
            coverTab: _tab,
            coverTexture: _texture,
            coverFont: _font,
            innerPaper: _paper,
            innerPaperColor: _paperColor,
            iconX: _iconX,
            iconY: _iconY,
          ),
        );
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('표지를 저장했어요')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.journal;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 고정 헤더: 손잡이·제목·미리보기. 아래 칩만 스크롤되어 표지에
          // 적용되는 모습을 스크롤하지 않고도 실시간으로 볼 수 있다.
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(_previewPage == 0 ? '표지 꾸미기' : '속지 꾸미기',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('저장',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 표지↔속지 미리보기 캐러셀: 아래 "표지/속지" 탭으로 전환한다.
          // 좌우 스와이프는 막아 둔다(표지 위 아이콘을 좌우로 끌 때 페이지가
          // 같이 넘어가 버리는 충돌을 피하려고). 전환은 탭 버튼이 담당.
          SizedBox(
            height: 148,
            child: PageView(
              controller: _previewCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _previewPage = i),
              children: [
                Center(
                  child: SizedBox(
                    width: _kPreviewW,
                    height: _kPreviewH,
                    // 표지 위를 끌거나 탭하면 아이콘이 그 자리로 이동(스티커처럼).
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: _onIconPanStart,
                      onPanUpdate: _onIconPanUpdate,
                      onPanEnd: _onIconPanEnd,
                      child: JournalCover(
                        color: _color,
                        icon: _icon,
                        pattern: _pattern,
                        binding: _binding,
                        corner: _corner,
                        band: _band,
                        ribbon: _ribbon,
                        clip: _clip,
                        tab: _tab,
                        texture: _texture,
                        titleFont: coverFontFamily(_font),
                        title: _title.trim().isEmpty ? j.title : _title,
                        iconX: _iconX,
                        iconY: _iconY,
                        radius: 14,
                        iconSize: 30,
                        titleSize: 14,
                      ),
                    ),
                  ),
                ),
                Center(child: _paperPreview()),
              ],
            ),
          ),
          // 표지 페이지에서만: 아이콘을 끌어 옮길 수 있다는 안내.
          if (_previewPage == 0 && _icon != kNoCoverIcon)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Center(
                child: Text('아이콘을 집어서 끌어 옮겨보세요',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
              ),
            ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _previewTab('표지', 0),
                const SizedBox(width: 20),
                _previewTab('속지', 1),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  top: 20, bottom: 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                // 표지 탭(0)이면 표지 꾸미기만, 속지 탭(1)이면 속지 꾸미기만 보인다.
                children: _previewPage == 0 ? _coverSections(j) : _paperSections(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 속지 미리보기: 크림색 종이 한 장 위에 선택한 속지 무늬를 그린다.
  Widget _paperPreview() => Container(
        width: 110,
        height: 140,
        decoration: BoxDecoration(
          color: paperColorOf(_paperColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: PaperPainter(_paper, spacing: 16),
            child: const SizedBox.expand(),
          ),
        ),
      );

  /// 미리보기 전환 탭("표지"/"속지"). 탭하면 해당 페이지로 애니메이션.
  Widget _previewTab(String label, int page) {
    final selected = _previewPage == page;
    return GestureDetector(
      onTap: () => _previewCtrl.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textHint)),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
