import 'package:flutter/material.dart';

/// 일기장 표지(책 모양)를 그리는 공용 렌더러.
///
/// 책장·꾸미기 시트 미리보기·(추후)꾸미기샵·상세 헤더가 모두 이 위젯을 써서
/// 새 꾸미기 레이어(패턴/제본/잠금 등)는 여기 한 곳만 추가하면 됩니다.
/// 그라데이션 + 책등(spine) + (선택)기록수 배지 + 아이콘 + (선택)제목.
class JournalCover extends StatelessWidget {
  const JournalCover({
    super.key,
    required this.color,
    required this.icon,
    this.title,
    this.entryCount,
    this.radius = 14,
    this.iconSize = 34,
    this.titleSize = 15,
    this.centerIcon = false,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 10, 12),
  });

  /// ARGB int (Journal.coverColor).
  final int color;
  final String icon;

  /// 표지 안에 흰 글씨로 넣을 제목. null이면 제목 없음(예: 앱아이콘 레이아웃).
  final String? title;

  /// 우상단 기록 수 배지. null이면 숨김.
  final int? entryCount;
  final double radius;
  final double iconSize;
  final double titleSize;

  /// true면 아이콘을 가운데 정렬(제목은 표지 밖에 둘 때).
  final bool centerIcon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return Container(
      decoration: coverBoxDecoration(c, radius),
      child: Stack(
        children: [
          _CoverSpine(radius: radius),
          if (entryCount != null) _CoverCountBadge(count: entryCount!),
          if (centerIcon)
            Center(child: Text(icon, style: TextStyle(fontSize: iconSize)))
          else
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(icon, style: TextStyle(fontSize: iconSize)),
                  if (title != null)
                    Text(title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            height: 1.15)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 표지 그라데이션 + 부드러운 그림자 (모든 표지 스타일이 공유).
BoxDecoration coverBoxDecoration(Color color, double radius) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        colors: [color, color.withValues(alpha: 0.78)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );

class _CoverSpine extends StatelessWidget {
  const _CoverSpine({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) => Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: Container(
          width: 6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.16),
            borderRadius:
                BorderRadius.horizontal(left: Radius.circular(radius)),
          ),
        ),
      );
}

class _CoverCountBadge extends StatelessWidget {
  const _CoverCountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Positioned(
        top: 7,
        right: 7,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ),
      );
}
