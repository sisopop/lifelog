import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Hint-styled stat lines shared by the day/tag/place/mood entries-screen
/// headers. Each builder returns a spreadable list that carries its own 4px
/// top spacing, so a header Column can just spread the badges it wants:
///
/// ```dart
/// ...statBadgeAvgChars(avgChars),
/// ...statBadgeFavorites(favorites),
/// ```
///
/// A builder returns an empty list when the value is below its display
/// threshold, rendering nothing (and adding no spacing).
const _hintStyle = TextStyle(fontSize: 12, color: AppColors.textHint);

const _weekdayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
const _dayPartNames = ['새벽', '아침', '오후', '저녁'];

List<Widget> _badge(String text) =>
    [const SizedBox(height: 4), Text(text, style: _hintStyle)];

/// '✍️ 평균 N자' — average characters per record.
List<Widget> statBadgeAvgChars(int avgChars) =>
    avgChars > 0 ? _badge('✍️ 평균 $avgChars자') : const [];

/// '⭐ 즐겨찾기 N개' — favorited records in this scope.
List<Widget> statBadgeFavorites(int favorites) =>
    favorites > 0 ? _badge('⭐ 즐겨찾기 $favorites개') : const [];

/// '🎨 꾸민 기록 N개' — records with a decorated page canvas.
List<Widget> statBadgeDecorated(int decorated) =>
    decorated > 0 ? _badge('🎨 꾸민 기록 $decorated개') : const [];

/// '📷 사진 있는 기록 N개' — records carrying at least one photo.
List<Widget> statBadgePhotos(int photos) =>
    photos > 0 ? _badge('📷 사진 있는 기록 $photos개') : const [];

/// '📝 제목 있는 기록 N개' — records carrying a non-empty title.
List<Widget> statBadgeTitled(int titled) =>
    titled > 0 ? _badge('📝 제목 있는 기록 $titled개') : const [];

/// '✍️ AI 요약 있는 기록 N개' — records carrying a non-empty AI summary.
List<Widget> statBadgeAiSummary(int summaries) =>
    summaries > 0 ? _badge('✍️ AI 요약 있는 기록 $summaries개') : const [];

/// '📓 저널1 · 저널2 …' — up to four owning journals.
List<Widget> statBadgeJournalNames(List<String> names) =>
    names.isNotEmpty ? _badge('📓 ${names.take(4).join(' · ')}') : const [];

/// '📆 주로 X요일' — the busiest weekday (1=Mon … 7=Sun).
List<Widget> statBadgeWeekday(int? weekday) =>
    weekday != null ? _badge('📆 주로 ${_weekdayNames[weekday]}요일') : const [];

/// '🕘 주로 X에 기록' — the busiest day part (0=새벽 … 3=저녁).
List<Widget> statBadgeDayPart(int? dayPart) =>
    dayPart != null ? _badge('🕘 주로 ${_dayPartNames[dayPart]}에 기록') : const [];
