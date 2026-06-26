import 'package:flutter/material.dart';

import 'cover_tab.dart';

/// 속지에 끼워진 인덱스 탭이 표지 '우측'으로 삐져나온 모습을 절차적으로 그리는
/// 페인터. 표지 면 위에 그리지 않고, 표지 우변 바로 밖에서 작은 둥근 탭 3개만
/// 보이게 한다(책갈피=아래, 클립=위의 우측판). 'none'은 아무것도 안 그린다.
/// 이 레이어는 ClipRRect 밖에서 그려지므로 표지 경계 오른쪽으로 넘어가 보인다.
class CoverTabPainter extends CustomPainter {
  const CoverTabPainter(this.tab, {this.scale = 1.0});

  /// cover_tab.dart의 탭 id.
  final String tab;

  /// 작은 미리보기/큰 책장에서 탭 크기를 맞추기 위한 배율.
  final double scale;

  /// id별 탭 3개의 색상 조합(위→아래).
  static const Map<String, List<int>> _palettes = {
    'colorful': [0xFFEF6F6C, 0xFFE6B85C, 0xFF5FC9A6],
    'pink': [0xFFF4A6C0, 0xFFEE89B3, 0xFFD75F92],
    'blue': [0xFF9FC0F2, 0xFF6B97E0, 0xFF4E79CC],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final id = normalizeCoverTab(tab);
    final colors = _palettes[id];
    if (colors == null) return; // none.

    // 우변 밖으로 삐져나오는 길이와 탭 높이(표지 크기에 비례).
    final peek = (size.width * 0.09).clamp(7.0, 15.0);
    final th = (size.height * 0.11).clamp(8.0, 18.0); // 탭 한 개 높이.
    final gap = th * 0.5;
    final left = size.width - 2; // 표지 우변 살짝 안(밖에서 나오는 느낌).
    final right = size.width + peek;
    final r = Radius.circular(th * 0.32);

    // 탭 3개를 세로 가운데에 모은다(상단 배지·하단 제목과 안 겹침).
    final total = colors.length * th + (colors.length - 1) * gap;
    var top = (size.height - total) / 2;

    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.18);
    for (final argb in colors) {
      final rect = RRect.fromLTRBAndCorners(
        left,
        top,
        right,
        top + th,
        topRight: r,
        bottomRight: r,
      );
      // 드롭 그림자(표지 오른쪽 밖에 떨어지는 느낌).
      canvas.drawRRect(rect.shift(const Offset(1.4, 1.6)), shadow);
      // 탭 본체.
      canvas.drawRRect(rect, Paint()..color = Color(argb));
      // 위쪽 가장자리 하이라이트.
      canvas.drawLine(
        Offset(left + 1, top + 1.2),
        Offset(right - th * 0.32, top + 1.2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..strokeWidth = 1.0,
      );
      top += th + gap;
    }
  }

  @override
  bool shouldRepaint(CoverTabPainter old) =>
      old.tab != tab || old.scale != scale;
}
