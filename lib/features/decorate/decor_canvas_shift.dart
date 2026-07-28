// 꾸미기 캔버스에서 텍스트박스를 인라인 편집할 때, 자판이 상자를 가리지 않도록
// 캔버스를 위로 얼마나 밀어야 하는지 계산하는 순수 함수.
//
// 캔버스는 가로 100% 고정 + 3:4 세로라(write_canvas_tabs.dart) 화면보다 길어서,
// 아래쪽에 놓인 상자는 자판이 뜨면 자판 뒤로 숨는다. 편집 중인 상자를 "자판 위
// 남은 공간"의 가운데로 올려 글이 보이게 한다(자판을 내리면 밀기 0 → 원래 캔버스).

/// 텍스트박스 편집바(자판 바로 위 서식바)가 가리는 높이.
const double kDecorFormatBarHeight = 56.0;

/// 편집 중인 텍스트박스를 자판 위 공간 가운데에 두기 위해 캔버스를 위로 밀 거리.
///
/// [canvasTop]/[canvasHeight]는 캔버스 상자의 위치·높이, [boxCenterY]는 상자
/// 중심의 캔버스 내 세로 비율(0~1, DecoLayer.y), [viewportHeight]는 자판 위에
/// 남은 세로 공간, [barHeight]는 편집바 높이다.
///
/// 되돌리는 값은 항상 0 이상(캔버스를 아래로 내리지는 않는다)이고 [canvasHeight]
/// 이하다(캔버스가 화면 위로 완전히 사라지지 않게).
double decorCanvasEditShift({
  required double canvasTop,
  required double canvasHeight,
  required double boxCenterY,
  required double viewportHeight,
  double barHeight = kDecorFormatBarHeight,
}) {
  final want = (viewportHeight - barHeight) / 2;
  final now = canvasTop + boxCenterY * canvasHeight;
  final shift = now - want;
  if (shift <= 0) return 0;
  return shift > canvasHeight ? canvasHeight : shift;
}

/// 편집 중인 상자가 **보이는 영역 밖(아래)** 인지 여부.
///
/// 웹은 자판 높이를 보고하지 않는 대신 브라우저가 창을 줄이므로, "자판이 떴다"를
/// 알 수 없다. 그래서 웹에서는 상자가 실제로 보이는 영역(뷰포트에서 편집바 높이를
/// 뺀 아래끝) 밑으로 내려갔을 때만 캔버스를 민다(불필요한 튐 방지).
bool decorCanvasBoxHidden({
  required double canvasTop,
  required double canvasHeight,
  required double boxCenterY,
  required double viewportHeight,
  double barHeight = kDecorFormatBarHeight,
}) =>
    canvasTop + boxCenterY * canvasHeight > viewportHeight - barHeight;
