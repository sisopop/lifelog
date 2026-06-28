part of 'cover_decorate_sheet.dart';

/// 꾸미기 시트의 칩 목록(섹션 빌더). 분량이 커서 메인 파일에서 분리했다.
/// 같은 라이브러리의 part라 _CoverDecorateSheetState의 private 멤버
/// (_color/_icon/_pick* 등)에 그대로 접근한다.
extension _DecorateSections on _CoverDecorateSheetState {
  /// 표지 탭에서 보이는 섹션(표지 관련 꾸미기만). 섹션 사이는 SizedBox(20)로
  /// 띄운다. (첫 섹션은 스크롤 padding top:20이 여백을 대신해 앞에 SizedBox 없음.)
  /// 속지 칩은 _paperSections()로 분리해 속지 탭에서만 보인다.
  List<Widget> _coverSections(Journal j) {
    final palette = coverPaletteFor(j.coverColor);
    final icons = coverIconPaletteFor(j.displayIcon);
    return [
      _nameSection(),
      const SizedBox(height: 20),
      _themeSection(),
      const SizedBox(height: 20),
      _colorSection(palette),
      const SizedBox(height: 20),
      _iconSection(icons),
      const SizedBox(height: 20),
      // 재질/제본/모서리/밴드: 표지 면 위 레이어 → ClipRRect로 둥글게 자른다.
      _clippedLayerSection(
        title: '재질',
        ids: coverTexturePalette,
        selectedId: _texture,
        onPick: _pickTexture,
        label: coverTextureLabel,
        cover: (id) => JournalCover(
          color: _color,
          icon: '',
          texture: id,
          textureScale: 0.7,
          radius: 8,
          iconSize: 0,
        ),
      ),
      const SizedBox(height: 20),
      _fontSection(),
      // 표지 패턴 섹션은 v1 패턴이 충분히 예쁘지 않아 숨김 처리.
      // 모델/DB/페인터는 그대로 두고, 더 나은 패턴이 준비되면 되살린다.
      const SizedBox(height: 20),
      _clippedLayerSection(
        title: '제본',
        ids: coverBindingPalette,
        selectedId: _binding,
        onPick: _pickBinding,
        label: coverBindingLabel,
        cover: (id) => JournalCover(
          color: _color,
          icon: '',
          binding: id,
          bindingScale: 0.8,
          radius: 8,
          iconSize: 0,
        ),
      ),
      const SizedBox(height: 20),
      _clippedLayerSection(
        title: '모서리',
        ids: coverCornerPalette,
        selectedId: _corner,
        onPick: _pickCorner,
        label: coverCornerLabel,
        cover: (id) => JournalCover(
          color: _color,
          icon: '',
          corner: id,
          cornerScale: 0.7,
          radius: 8,
          iconSize: 0,
        ),
      ),
      const SizedBox(height: 20),
      _clippedLayerSection(
        title: '밴드',
        ids: coverBandPalette,
        selectedId: _band,
        onPick: _pickBand,
        label: coverBandLabel,
        cover: (id) => JournalCover(
          color: _color,
          icon: '',
          band: id,
          bandScale: 0.7,
          radius: 8,
          iconSize: 0,
        ),
      ),
      const SizedBox(height: 20),
      // 책갈피/클립/인덱스 탭: 표지 밖으로 삐져나오는 레이어 → ClipRRect 없이
      // 표지를 칩 안쪽으로 띄워(padding) 삐져나온 부분이 보이게 한다.
      _peekLayerSection(
        title: '책갈피',
        ids: coverRibbonPalette,
        selectedId: _ribbon,
        onPick: _pickRibbon,
        label: coverRibbonLabel,
        // 책갈피 끈은 표지 아래로 삐져나오므로 표지를 위로 띄운다.
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 11),
        cover: (id) => JournalCover(
          color: _color,
          icon: '',
          ribbon: id,
          radius: 6,
          iconSize: 0,
        ),
      ),
      const SizedBox(height: 20),
      _peekLayerSection(
        title: '클립',
        ids: coverClipPalette,
        selectedId: _clip,
        onPick: _pickClip,
        label: coverClipLabel,
        // 클립은 표지 윗변 위로 삐져나오므로 표지를 아래로 내린다.
        padding: const EdgeInsets.fromLTRB(8, 11, 8, 4),
        cover: (id) => JournalCover(
          color: _color,
          icon: '',
          clip: id,
          radius: 6,
          iconSize: 0,
        ),
      ),
      const SizedBox(height: 20),
      _peekLayerSection(
        title: '인덱스 탭',
        ids: coverTabPalette,
        selectedId: _tab,
        onPick: _pickTab,
        label: coverTabLabel,
        // 인덱스 탭은 표지 우변 밖으로 삐져나오므로 표지를 왼쪽으로 당긴다.
        padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
        cover: (id) => JournalCover(
          color: _color,
          icon: '',
          tab: id,
          radius: 6,
          iconSize: 0,
        ),
      ),
    ];
  }

  /// 속지 탭에서 보이는 섹션(속지 무늬 + 종이 색만).
  List<Widget> _paperSections() => [_paperSection()];

  /// 속지(내지) — 읽기 화면 배경에 깔리는 종이 무늬. 칩에 작은 종이를 그려 보여준다.
  Widget _paperSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle('속지'),
          const SizedBox(height: 4),
          const Text('일기를 읽을 때 배경에 깔려요',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverPaperPalette.map((p) {
              final selected = p.id == _paper;
              return GestureDetector(
                onTap: () => _pickPaper(p.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: _chipBorder(selected),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: paperColorOf(_paperColor)),
                          child: CustomPaint(
                            painter: PaperPainter(p.id, spacing: 8),
                            size: const Size.square(48),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _chipLabel(p.label, selected),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _sectionTitle('종이 색'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: paperColorPalette.map((pc) {
              final selected = pc.id == _paperColor;
              return GestureDetector(
                onTap: () => _pickPaperColor(pc.id),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pc.color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: AppColors.primary, width: 3)
                        : Border.all(color: AppColors.divider),
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                          color: AppColors.primary, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      );

  /// 섹션 제목.
  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));

  /// 칩 라벨(선택 시 강조).
  Widget _chipLabel(String text, bool selected) => Text(text,
      style: TextStyle(
          fontSize: 11,
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500));

  /// 48x48 표지 칩 테두리(선택 시 primary).
  BoxDecoration _chipBorder(bool selected) => BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: selected
            ? Border.all(color: AppColors.primary, width: 2.5)
            : Border.all(color: AppColors.divider),
      );

  /// 일기장 이름(제목) 변경 입력칸. 입력하면 미리보기 표지에 실시간 반영되고,
  /// "저장"을 눌러야 실제로 반영된다(빈 값이면 원래 이름 유지).
  Widget _nameSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle('일기장 이름'),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            onChanged: _onTitleChanged,
            textInputAction: TextInputAction.done,
            maxLength: 30,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '일기장 이름을 입력하세요',
              counterText: '',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      );

  /// "한 번에 분위기를 바꾸는" 테마 프리셋.
  Widget _themeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle('테마'),
          const SizedBox(height: 4),
          const Text('한 번에 분위기를 바꿔요',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverThemes.map((t) {
              return GestureDetector(
                onTap: () => _pickTheme(t),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 72,
                      child: JournalCover(
                        color: t.color,
                        icon: t.icon,
                        texture: t.texture,
                        textureScale: 0.7,
                        binding: t.binding,
                        bindingScale: 0.8,
                        corner: t.corner,
                        cornerScale: 0.7,
                        band: t.band,
                        bandScale: 0.7,
                        ribbon: t.ribbon,
                        clip: t.clip,
                        tab: t.tab,
                        radius: 8,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(t.label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );

  /// 표지 색(원형 스와치).
  Widget _colorSection(List<int> palette) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle('표지 색'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: palette.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => _pick(c),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.black87, width: 3)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      );

  /// 표지 아이콘(이모지 + "없음").
  Widget _iconSection(List<String> icons) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle('표지 아이콘'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: icons.map((e) {
              final selected = e == _icon;
              final isNone = e == kNoCoverIcon;
              return GestureDetector(
                onTap: () => _pickIcon(e),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: AppColors.primary, width: 2.5)
                        : Border.all(color: AppColors.divider),
                  ),
                  child: isNone
                      ? const Icon(Icons.block,
                          size: 20, color: AppColors.textHint)
                      : Text(e, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
        ],
      );

  /// 제목 글꼴(라벨을 그 글꼴로 렌더).
  Widget _fontSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle('제목 글꼴'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: coverFontPalette.map((f) {
              final selected = f.id == _font;
              return GestureDetector(
                onTap: () => _pickFont(f.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: AppColors.primary, width: 2.5)
                        : Border.all(color: AppColors.divider),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: f.family,
                      fontWeight: FontWeight.w700,
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

}
