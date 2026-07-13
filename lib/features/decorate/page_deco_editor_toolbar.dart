part of 'page_deco_editor.dart';

/// 선택된 레이어에 적용하는 편집 툴바(크기·이동·회전·정렬·복제·삭제 등).
/// 버튼이 많아 좁은 화면에서 넘칠 수 있어 가로 스크롤로 감싼다.
class _SelectedToolbar extends StatelessWidget {
  const _SelectedToolbar(this.s);

  final _PageDecoEditorState s;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 삭제를 맨 앞에 둬 선택하자마자 바로 보이게 한다(끝까지 스크롤 불필요).
            _toolBtn(Icons.delete_outline, '삭제', s._deleteSelected,
                color: AppColors.moodHard),
            _toolBtn(Icons.layers_outlined, '다음 레이어', s._selectNextLayer),
            _toolBtn(Icons.layers_clear_outlined, '이전 레이어',
                s._selectPreviousLayer),
            _toolBtn(Icons.remove, '작게',
                () => s._applyToSelected((c, id) => stepLayerScale(c, id, -0.15))),
            _toolBtn(Icons.add, '크게',
                () => s._applyToSelected((c, id) => stepLayerScale(c, id, 0.15))),
            _toolBtn(Icons.aspect_ratio, '원래크기',
                () => s._applyToSelected(resetLayerScale)),
            _toolBtn(Icons.keyboard_arrow_up, '위로',
                () => s._applyToSelected((c, id) => nudgeLayer(c, id, 0, -0.05))),
            _toolBtn(Icons.keyboard_arrow_down, '아래로',
                () => s._applyToSelected((c, id) => nudgeLayer(c, id, 0, 0.05))),
            _toolBtn(Icons.keyboard_arrow_left, '왼쪽으로',
                () => s._applyToSelected((c, id) => nudgeLayer(c, id, -0.05, 0))),
            _toolBtn(Icons.keyboard_arrow_right, '오른쪽으로',
                () => s._applyToSelected((c, id) => nudgeLayer(c, id, 0.05, 0))),
            _toolBtn(Icons.opacity, '흐리게',
                () => s._applyToSelected((c, id) => stepLayerOpacity(c, id, -0.2))),
            _toolBtn(Icons.opacity_outlined, '진하게',
                () => s._applyToSelected((c, id) => stepLayerOpacity(c, id, 0.2))),
            _toolBtn(Icons.format_color_reset_outlined, '또렷하게',
                () => s._applyToSelected(resetLayerOpacity)),
            _toolBtn(Icons.rotate_left, '왼쪽',
                () => s._applyToSelected((c, id) => stepLayerRotation(c, id, -15))),
            _toolBtn(Icons.rotate_right, '오른쪽',
                () => s._applyToSelected((c, id) => stepLayerRotation(c, id, 15))),
            _toolBtn(Icons.rotate_90_degrees_cw, '90°',
                () => s._applyToSelected(rotateLayerQuarter)),
            _toolBtn(Icons.straighten, '똑바로',
                () => s._applyToSelected(straightenLayer)),
            _toolBtn(Icons.screen_rotation_alt, '직각 정렬',
                () => s._applyToSelected(snapLayerRotation)),
            _toolBtn(Icons.center_focus_strong_outlined, '가운데',
                () => s._applyToSelected(centerLayer)),
            _toolBtn(Icons.align_horizontal_center, '가로중앙',
                () => s._applyToSelected(centerLayerHorizontally)),
            _toolBtn(Icons.align_vertical_center, '세로중앙',
                () => s._applyToSelected(centerLayerVertically)),
            _toolBtn(Icons.swap_horiz, '좌우반전',
                () => s._applyToSelected(mirrorLayerX)),
            _toolBtn(Icons.swap_vert_outlined, '상하반전',
                () => s._applyToSelected(mirrorLayerY)),
            _toolBtn(Icons.transform, '대각반전',
                () => s._applyToSelected(mirrorLayerPoint)),
            _toolBtn(Icons.grid_4x4, '격자 정렬',
                () => s._applyToSelected(snapLayerToGrid)),
            _toolBtn(Icons.flip, '좌우', () => s._applyToSelected(flipLayerX)),
            _toolBtn(Icons.swap_vert, '상하', () => s._applyToSelected(flipLayerY)),
            _toolBtn(Icons.restart_alt, '변형 초기화',
                () => s._applyToSelected(resetLayerTransform)),
            if (s._selected?.kind == DecoKind.text) ...[
              _toolBtn(Icons.edit_outlined, '편집',
                  () => s._editText(s._selected!)),
              _toolBtn(Icons.format_indent_decrease, '자간-',
                  () => s._applyToSelected(
                      (c, id) => stepLayerLetterSpacing(c, id, -1))),
              _toolBtn(Icons.format_indent_increase, '자간+',
                  () => s._applyToSelected(
                      (c, id) => stepLayerLetterSpacing(c, id, 1))),
              _toolBtn(Icons.format_clear, '자간 초기화',
                  () => s._applyToSelected(resetLayerLetterSpacing)),
            ],
            _toolBtn(Icons.copy_all_outlined, '복제', s._duplicateSelected),
            _toolBtn(Icons.arrow_upward, '앞으로',
                () => s._applyToSelected(stepLayerForward)),
            _toolBtn(Icons.arrow_downward, '뒤로',
                () => s._applyToSelected(stepLayerBackward)),
            _toolBtn(Icons.flip_to_front, '맨 앞',
                () => s._applyToSelected(bringLayerToFront)),
            _toolBtn(Icons.flip_to_back, '맨 뒤',
                () => s._applyToSelected(sendLayerToBack)),
            _toolBtn(Icons.delete_sweep_outlined, '종류 삭제', s._deleteSameKind,
                color: AppColors.moodHard),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap,
      {Color color = AppColors.textPrimary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        // 툴바가 가로 스크롤이라 넘침 걱정 없이 여유 있는 가로 여백을 준다.
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
