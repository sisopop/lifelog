part of 'cover_decorate_sheet.dart';

/// 표지 위 레이어용 공통 칩 섹션 빌더. cover_decorate_sections.dart가 500줄을
/// 넘어 분리했다. 같은 라이브러리의 part라 _CoverDecorateSheetState의 private
/// 멤버(_sectionTitle/_chipLabel/_chipBorder 등)에 그대로 접근한다.
extension _DecorateLayers on _CoverDecorateSheetState {
  /// 표지 면 위 레이어(재질·제본·모서리·밴드)용 칩 섹션.
  /// 표지를 ClipRRect로 둥글게 자른다.
  Widget _clippedLayerSection({
    required String title,
    required List<String> ids,
    required String selectedId,
    required void Function(String) onPick,
    required String Function(String) label,
    required JournalCover Function(String id) cover,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ids.map((id) {
              final selected = id == selectedId;
              return GestureDetector(
                onTap: () => onPick(id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: _chipBorder(selected),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: cover(id),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _chipLabel(label(id), selected),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );

  /// 표지 밖으로 삐져나오는 레이어(책갈피·클립·인덱스 탭)용 칩 섹션.
  /// ClipRRect 없이 표지를 padding으로 칩 안쪽에 띄워 삐져나온 부분이 보이게 한다.
  Widget _peekLayerSection({
    required String title,
    required List<String> ids,
    required String selectedId,
    required void Function(String) onPick,
    required String Function(String) label,
    required EdgeInsets padding,
    required JournalCover Function(String id) cover,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ids.map((id) {
              final selected = id == selectedId;
              return GestureDetector(
                onTap: () => onPick(id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: padding,
                      decoration: _chipBorder(selected),
                      child: cover(id),
                    ),
                    const SizedBox(height: 4),
                    _chipLabel(label(id), selected),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      );
}
