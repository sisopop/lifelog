/// Pure helper for the read-view photo carousel's aspect ratio.
///
/// Given the intrinsic pixel size of the (first) photo, returns the ratio the
/// gallery box should use so a photo shows close to its natural shape instead of
/// being force-cropped to a square (the user's complaint: "비율이 자동으로 1:1로
/// 바뀌는듯"). Clamped to a sensible range so an extreme panorama/strip can't make
/// the carousel absurdly short or tall.
///
/// - null / zero / invalid dimensions → 1.0 (square fallback = the legacy look,
///   also what a not-yet-decoded image shows for a frame or two)
/// - otherwise `width / height` clamped to `[3/4 .. 4/3]`
double galleryAspectRatio(int? width, int? height) {
  if (width == null || height == null || width <= 0 || height <= 0) return 1.0;
  final r = width / height;
  const min = 3 / 4;
  const max = 4 / 3;
  if (r < min) return min;
  if (r > max) return max;
  return r;
}
