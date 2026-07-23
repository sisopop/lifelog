// 리치텍스트 툴바의 **선택형** 서식 피커(글꼴·글자크기·글자색·형광펜).
//
// 예전에는 버튼을 누를 때마다 값이 순환(cycle)했지만, 사용자가 원하는 값을 바로
// 고르도록 바텀시트 피커로 바꿨다. 특히 색은 **색상표(그리드)**에서 고른다.
// 편집기(textbox_rich_editor.dart·body_rich_editor.dart)가 공용으로 쓴다.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'cover_font.dart';
import 'textbox_rich.dart';

/// 피커 결과 래퍼. `null` 반환 = 취소, `RichPick(null)` = "기본/지우기" 선택,
/// `RichPick(값)` = 해당 값 선택. (선택값 자체가 null일 수 있어 래퍼로 구분한다.)
class RichPick<T> {
  const RichPick(this.value);
  final T value;
}

/// 글자 크기 선택지. [token]은 저장값(null=기본, 'small'/'large'/'huge').
class RichSizeOption {
  const RichSizeOption(this.token, this.label);
  final String? token;
  final String label;
}

const List<RichSizeOption> kRichSizeOptions = [
  RichSizeOption(null, '기본'),
  RichSizeOption('small', '작게'),
  RichSizeOption('large', '크게'),
  RichSizeOption('huge', '아주 크게'),
];

/// [token]에 해당하는 크기 선택지의 인덱스(없으면 0=기본).
int richSizeOptionIndex(String? token) {
  final i = kRichSizeOptions.indexWhere((o) => o.token == token);
  return i < 0 ? 0 : i;
}

/// 글자색 **색상표**(무채색 → 선명 → 진함 → 연함, 8열 × 4행).
const List<Color> kRichInkChart = [
  Color(0xFF000000), Color(0xFF444444), Color(0xFF666666), Color(0xFF888888),
  Color(0xFFAAAAAA), Color(0xFFCCCCCC), Color(0xFFEEEEEE), Color(0xFFFFFFFF),
  Color(0xFFE5484D), Color(0xFFEE7B2B), Color(0xFFF2B807), Color(0xFF2E9E5B),
  Color(0xFF17A2B8), Color(0xFF2F6FEB), Color(0xFF7C4DFF), Color(0xFFD6409F),
  Color(0xFF9E1B1F), Color(0xFFB35510), Color(0xFFB08600), Color(0xFF1E7A43),
  Color(0xFF10707E), Color(0xFF1E4FB0), Color(0xFF5A34C0), Color(0xFF9E2A73),
  Color(0xFFEF9A9A), Color(0xFFFFCC80), Color(0xFFFFE082), Color(0xFFA5D6A7),
  Color(0xFF80DEEA), Color(0xFF90CAF9), Color(0xFFCE93D8), Color(0xFFF48FB1),
];

/// 형광펜 **색상표**(파스텔 8색).
const List<Color> kRichHighlightChart = [
  Color(0xFFFFF1A8), Color(0xFFFFD6E0), Color(0xFFCDEFD8), Color(0xFFCFE4FF),
  Color(0xFFEAD9FF), Color(0xFFFFE0B3), Color(0xFFD6F5F5), Color(0xFFEDEDED),
];

Future<T?> _sheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(child: child),
  );
}

Widget _sheetTitle(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    );

/// 글자 크기 선택 바텀시트. [current]=현재 크기 토큰.
Future<RichPick<String?>?> showRichSizePicker(
    BuildContext context, String? current) {
  return _sheet<RichPick<String?>>(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetTitle('글자 크기'),
        for (final o in kRichSizeOptions)
          ListTile(
            title: Text(o.label,
                style: TextStyle(
                    fontSize: 16 * richSizeMultiplier(o.token),
                    color: AppColors.textPrimary)),
            trailing: o.token == current
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () => Navigator.pop(context, RichPick<String?>(o.token)),
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

/// 글꼴 선택 바텀시트. [current]=현재 글꼴 family(null=기본).
Future<RichPick<String?>?> showRichFontPicker(
    BuildContext context, String? current) {
  return _sheet<RichPick<String?>>(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetTitle('글꼴'),
        for (final f in coverFontPalette)
          ListTile(
            title: Text(f.label,
                style: TextStyle(
                    fontFamily: f.family,
                    fontSize: 17,
                    color: AppColors.textPrimary)),
            trailing: f.family == current
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () => Navigator.pop(context, RichPick<String?>(f.family)),
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

/// 색상표 그리드 바텀시트(글자색·형광펜 공용). [palette]=색 목록,
/// [current]=현재 색 hex(소문자), [title]/[clearLabel]로 문구를 바꾼다.
/// "지우기" 선택 시 `RichPick(null)`을 돌려준다.
Future<RichPick<String?>?> showRichColorPicker(
  BuildContext context, {
  required List<Color> palette,
  required String? current,
  required String title,
  required String clearLabel,
}) {
  final cur = current?.toLowerCase();
  return _sheet<RichPick<String?>>(
    context,
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sheetTitle(title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final c in palette)
                _swatch(context, c, richColorHex(c).toLowerCase() == cur),
            ],
          ),
        ),
        const Divider(height: 24),
        ListTile(
          leading: const Icon(Icons.format_color_reset,
              color: AppColors.textSecondary),
          title: Text(clearLabel,
              style: const TextStyle(color: AppColors.textPrimary)),
          onTap: () => Navigator.pop(context, const RichPick<String?>(null)),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

Widget _swatch(BuildContext context, Color c, bool selected) {
  return InkWell(
    onTap: () =>
        Navigator.pop(context, RichPick<String?>(richColorHex(c))),
    borderRadius: BorderRadius.circular(6),
    child: Container(
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.divider,
          width: selected ? 2.5 : 1,
        ),
      ),
      child: selected
          ? Icon(Icons.check,
              size: 16,
              color: c.computeLuminance() > 0.6
                  ? Colors.black87
                  : Colors.white)
          : null,
    ),
  );
}
