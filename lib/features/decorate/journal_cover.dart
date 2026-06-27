import 'package:flutter/material.dart';

import 'cover_band.dart';
import 'cover_band_painter.dart';
import 'cover_binding.dart';
import 'cover_binding_painter.dart';
import 'cover_clip.dart';
import 'cover_clip_painter.dart';
import 'cover_corner.dart';
import 'cover_corner_painter.dart';
import 'cover_pattern.dart';
import 'cover_pattern_painter.dart';
import 'cover_ribbon.dart';
import 'cover_ribbon_painter.dart';
import 'cover_tab.dart';
import 'cover_tab_painter.dart';
import 'cover_texture.dart';
import 'cover_texture_painter.dart';

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
    this.pattern = kNoCoverPattern,
    this.patternScale = 1.0,
    this.binding = kDefaultCoverBinding,
    this.bindingScale = 1.0,
    this.corner = kDefaultCoverCorner,
    this.cornerScale = 1.0,
    this.band = kDefaultCoverBand,
    this.bandScale = 1.0,
    this.ribbon = kDefaultCoverRibbon,
    this.ribbonScale = 1.0,
    this.clip = kDefaultCoverClip,
    this.clipScale = 1.0,
    this.tab = kDefaultCoverTab,
    this.tabScale = 1.0,
    this.texture = kDefaultCoverTexture,
    this.textureScale = 1.0,
    this.titleFont,
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

  /// 절차적 표지 패턴 id (cover_pattern.dart). 'none'이면 단색.
  final String pattern;

  /// 패턴 밀도 배율(작은 미리보기는 더 작게).
  final double patternScale;

  /// 제본 방식 id (cover_binding.dart). 'plain'이면 단색 책등.
  final String binding;

  /// 제본 코일 크기 배율(작은 미리보기는 더 작게).
  final double bindingScale;

  /// 모서리 장식 id (cover_corner.dart). 'none'이면 장식 없음.
  final String corner;

  /// 모서리 장식 크기 배율(작은 미리보기는 더 작게).
  final double cornerScale;

  /// 밴드(스트랩) id (cover_band.dart). 'none'이면 밴드 없음.
  final String band;

  /// 밴드 두께 배율(작은 미리보기는 더 작게).
  final double bandScale;

  /// 책갈피 리본 id (cover_ribbon.dart). 'none'이면 리본 없음.
  final String ribbon;

  /// 리본 폭 배율(작은 미리보기는 더 작게).
  final double ribbonScale;

  /// 클립(페이퍼클립) id (cover_clip.dart). 'none'이면 클립 없음.
  final String clip;

  /// 클립 크기 배율(작은 미리보기는 더 작게).
  final double clipScale;

  /// 우측 인덱스 탭 id (cover_tab.dart). 'none'이면 탭 없음.
  final String tab;

  /// 탭 크기 배율(작은 미리보기는 더 작게).
  final double tabScale;

  /// 표지 재질(질감) id (cover_texture.dart). 'none'이면 매끈한 단색.
  final String texture;

  /// 재질 질감 밀도 배율(작은 미리보기는 더 작게).
  final double textureScale;

  /// 제목에 적용할 fontFamily (cover_font.dart). null이면 테마 기본(Pretendard).
  final String? titleFont;

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
        // 책갈피 끈·클립은 표지 밖(아래·위)으로 삐져나와야 해서 잘라내지 않는다.
        clipBehavior: Clip.none,
        children: [
          // 표지 재질(질감): 면 전체에 깔리는 가장 아래 레이어.
          if (normalizeCoverTexture(texture) != kDefaultCoverTexture)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CustomPaint(
                  painter: CoverTexturePainter(texture, c, scale: textureScale),
                ),
              ),
            ),
          if (normalizeCoverPattern(pattern) != kNoCoverPattern)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CustomPaint(
                  painter: CoverPatternPainter(pattern, scale: patternScale),
                ),
              ),
            ),
          _CoverSpine(radius: radius),
          if (normalizeCoverBinding(binding) != kDefaultCoverBinding)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CustomPaint(
                  painter: CoverBindingPainter(binding, scale: bindingScale),
                ),
              ),
            ),
          if (normalizeCoverCorner(corner) != kDefaultCoverCorner)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CustomPaint(
                  painter: CoverCornerPainter(corner, scale: cornerScale),
                ),
              ),
            ),
          if (normalizeCoverBand(band) != kDefaultCoverBand)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CustomPaint(
                  painter: CoverBandPainter(band, scale: bandScale),
                ),
              ),
            ),
          // 책갈피 끈: 속지에 끼워져 표지 아래로 삐져나오므로 자르지 않는다.
          if (normalizeCoverRibbon(ribbon) != kDefaultCoverRibbon)
            Positioned.fill(
              child: CustomPaint(
                painter: CoverRibbonPainter(ribbon, scale: ribbonScale),
              ),
            ),
          // 클립: 표지 윗변에 물려 위로 삐져나오므로 자르지 않는다.
          if (normalizeCoverClip(clip) != kDefaultCoverClip)
            Positioned.fill(
              child: CustomPaint(
                painter: CoverClipPainter(clip, scale: clipScale),
              ),
            ),
          // 인덱스 탭: 속지에 끼워져 표지 우변 밖으로 삐져나오므로 자르지 않는다.
          if (normalizeCoverTab(tab) != kDefaultCoverTab)
            Positioned.fill(
              child: CustomPaint(
                painter: CoverTabPainter(tab, scale: tabScale),
              ),
            ),
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
                            fontFamily: titleFont,
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
