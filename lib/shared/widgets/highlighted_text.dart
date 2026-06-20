import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// One piece of text, flagged as a query match or not.
class HighlightSegment {
  const HighlightSegment(this.text, this.isMatch);
  final String text;
  final bool isMatch;

  @override
  bool operator ==(Object other) =>
      other is HighlightSegment &&
      other.text == text &&
      other.isMatch == isMatch;

  @override
  int get hashCode => Object.hash(text, isMatch);

  @override
  String toString() => 'HighlightSegment("$text", $isMatch)';
}

/// Splits [text] into match / non-match segments around every (case-insensitive)
/// occurrence of [query]. An empty/whitespace query yields the whole text as a
/// single non-match segment. Adjacent segments are preserved in order so that
/// joining their texts reproduces the original [text] exactly.
List<HighlightSegment> highlightSegments(String text, String query) {
  final q = query.trim();
  if (q.isEmpty || text.isEmpty) {
    return [HighlightSegment(text, false)];
  }
  final lowerText = text.toLowerCase();
  final lowerQuery = q.toLowerCase();
  final segments = <HighlightSegment>[];
  var start = 0;
  while (true) {
    final idx = lowerText.indexOf(lowerQuery, start);
    if (idx < 0) {
      if (start < text.length) {
        segments.add(HighlightSegment(text.substring(start), false));
      }
      break;
    }
    if (idx > start) {
      segments.add(HighlightSegment(text.substring(start, idx), false));
    }
    segments.add(HighlightSegment(
        text.substring(idx, idx + lowerQuery.length), true));
    start = idx + lowerQuery.length;
  }
  return segments;
}

/// Renders [text] with every occurrence of [query] visually emphasised.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final segments = highlightSegments(text, query);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final s in segments)
            TextSpan(
              text: s.text,
              style: s.isMatch
                  ? const TextStyle(
                      backgroundColor: AppColors.primarySoft,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    )
                  : null,
            ),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
