import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/session.dart';

const _kReadingTextScaleKey = 'reading_text_scale';

/// Selectable reading sizes for the entry detail body, smallest → largest.
const readingTextScales = <double>[0.9, 1.0, 1.15, 1.3];

/// Default when nothing has been chosen yet.
const defaultReadingTextScale = 1.0;

/// Human label for a scale value (falls back to a percentage if unknown).
String readingScaleLabel(double scale) {
  if (scale <= 0.9) return '작게';
  if (scale < 1.1) return '보통';
  if (scale < 1.25) return '크게';
  return '아주 크게';
}

/// Clamp an arbitrary stored value to the nearest supported scale so the UI
/// never shows an out-of-range size.
double normalizeReadingScale(double scale) {
  return readingTextScales.reduce(
      (a, b) => (scale - a).abs() <= (scale - b).abs() ? a : b);
}

/// Reading text scale for the entry detail screen, persisted across launches.
class ReadingTextScaleNotifier extends Notifier<double> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  double build() {
    final stored = _p.getDouble(_kReadingTextScaleKey);
    return stored == null ? defaultReadingTextScale : normalizeReadingScale(stored);
  }

  Future<void> set(double scale) async {
    final next = normalizeReadingScale(scale);
    state = next;
    await _p.setDouble(_kReadingTextScaleKey, next);
  }
}

final readingTextScaleProvider =
    NotifierProvider<ReadingTextScaleNotifier, double>(
        ReadingTextScaleNotifier.new);
