part of 'page_canvas.dart';

// 레이어의 위치를 옮기는 정렬/반전 순수함수 모음. page_canvas_ops.dart가 상한(500줄)에
// 가까워, 가운데 정렬·좌우/상하 위치 반전 계열을 여기로 분리했다(part라 라이브러리·import·
// 테스트는 그대로). 모두 원본 불변, 바뀔 게 없으면 같은 인스턴스를 그대로 돌려준다.

/// id 레이어를 페이지 정중앙(x=0.5, y=0.5)으로 옮긴 새 캔버스를 반환한다. 위치만
/// 바꾸고 크기·회전·z는 그대로. 가장자리로 밀려난 레이어를 한 번에 가운데로 모을
/// 때 쓴다. 이미 정중앙이거나 id가 없으면 원본 그대로. 원본은 불변.
PageCanvas centerLayer(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  if (l.x == 0.5 && l.y == 0.5) return canvas;
  return replaceLayer(canvas, l.copyWith(x: 0.5, y: 0.5));
}

/// id 레이어를 가로(x=0.5)로만 가운데 정렬한 새 캔버스를 반환한다. 세로 위치·크기·
/// 회전·z는 그대로. 가운데(x·y 둘 다)의 가로축판으로, 세로 위치는 유지한 채 좌우만
/// 중앙에 맞출 때 쓴다. 이미 가운데이거나 id가 없으면 원본 그대로. 원본은 불변.
PageCanvas centerLayerHorizontally(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.x == 0.5) return canvas;
  return replaceLayer(canvas, matches.first.copyWith(x: 0.5));
}

/// id 레이어를 세로(y=0.5)로만 가운데 정렬한 새 캔버스를 반환한다. 가로 위치·크기·
/// 회전·z는 그대로. centerLayerHorizontally의 세로축 짝으로, 가로 위치는 유지한 채
/// 위아래만 중앙에 맞출 때 쓴다. 이미 가운데이거나 id가 없으면 원본 그대로. 원본은 불변.
PageCanvas centerLayerVertically(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.y == 0.5) return canvas;
  return replaceLayer(canvas, matches.first.copyWith(y: 0.5));
}

/// id 레이어를 페이지 세로 중심선을 기준으로 좌우 반대 위치로 옮긴 새 캔버스를 반환한다
/// (x → 1-x). 왼쪽에 놓은 레이어를 대칭인 오른쪽 자리로(또는 그 반대로) 한 번에 보낼 때
/// 쓴다. 세로 위치·크기·회전·z는 그대로. 이미 중앙(x=0.5)이거나 id가 없으면 원본 그대로.
/// 원본은 불변. (좌우 뒤집기 flipLayerX는 겉모습만, 이건 위치만 반전.)
PageCanvas mirrorLayerX(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final nx = clampUnit(1.0 - l.x);
  if (nx == l.x) return canvas;
  return replaceLayer(canvas, l.copyWith(x: nx));
}

/// id 레이어를 페이지 가로 중심선을 기준으로 위아래 반대 위치로 옮긴 새 캔버스를 반환한다
/// (y → 1-y). 위쪽에 놓은 레이어를 대칭인 아래 자리로(또는 그 반대로) 한 번에 보낼 때
/// 쓴다. 가로 위치·크기·회전·z는 그대로. 이미 중앙(y=0.5)이거나 id가 없으면 원본 그대로.
/// 원본은 불변. mirrorLayerX의 세로축 짝. (상하 뒤집기 flipLayerY는 겉모습만, 이건 위치만.)
PageCanvas mirrorLayerY(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final ny = clampUnit(1.0 - l.y);
  if (ny == l.y) return canvas;
  return replaceLayer(canvas, l.copyWith(y: ny));
}

/// id 레이어를 페이지 정중앙을 기준으로 점 대칭(180°) 위치로 옮긴 새 캔버스를 반환한다
/// (x→1-x, y→1-y). mirrorLayerX·mirrorLayerY를 한 번에 적용한 것과 같아, 대각선 반대
/// 자리로 보낼 때 쓴다. 크기·회전·z는 그대로. 이미 정중앙(x=0.5,y=0.5)이거나 id가 없으면
/// 원본 그대로. 원본은 불변.
PageCanvas mirrorLayerPoint(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final nx = clampUnit(1.0 - l.x);
  final ny = clampUnit(1.0 - l.y);
  if (nx == l.x && ny == l.y) return canvas;
  return replaceLayer(canvas, l.copyWith(x: nx, y: ny));
}

/// id 레이어의 위치(x,y)를 가장 가까운 0.1 격자에 맞춰 반올림한 새 캔버스를 반환한다
/// (예 0.23→0.2, 0.27→0.3). 드래그로 대충 놓은 레이어를 가지런한 격자 위치로 정돈할 때
/// 쓴다. 크기·회전·z는 그대로. 이미 격자 위(바뀔 게 없음)이거나 id가 없으면 원본 그대로.
/// 원본은 불변.
PageCanvas snapLayerToGrid(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final nx = clampUnit((l.x * 10).round() / 10);
  final ny = clampUnit((l.y * 10).round() / 10);
  if (nx == l.x && ny == l.y) return canvas;
  return replaceLayer(canvas, l.copyWith(x: nx, y: ny));
}
