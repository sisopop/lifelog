// PageCanvas 위의 순수 편집 연산 모음.
//
// 모델(page_canvas.dart)이 500줄 상한에 다다라, 레이어를 더하고·지우고·옮기고·
// 뒤집는 등 캔버스를 변형하는 순수함수들을 이 part 파일로 분리했다. 모두 원본을
// 건드리지 않고 새 [PageCanvas]를 돌려주며(불변), 새 캔버스를 만들 때 항상
// paper·paperColorValue를 그대로 이어 준다(누락하면 무늬·바탕색이 날아간다).
part of 'page_canvas.dart';

/// 사진 레이어를 캔버스 맨 위에 추가한 새 캔버스를 반환한다. [path]가 비어 있으면
/// 잘못된 추가를 막기 위해 원본을 그대로 돌려준다. [x],[y]는 중심 비율(0~1로 가둠).
/// 원본은 불변.
PageCanvas addPhotoLayer(
  PageCanvas canvas,
  String id,
  String path, {
  double x = 0.5,
  double y = 0.4,
}) {
  if (path.trim().isEmpty) return canvas;
  return addLayer(
    canvas,
    DecoLayer(
      id: id,
      kind: DecoKind.photo,
      value: path,
      x: clampUnit(x),
      y: clampUnit(y),
    ),
  );
}

/// 글자(메모) 레이어를 캔버스 맨 위에 추가한 새 캔버스를 반환한다. 공백뿐인
/// 글자는 잘못된 추가를 막기 위해 원본을 그대로 돌려준다. 앞뒤 공백은 다듬는다.
/// [colorValue]는 글자 색(ARGB, null이면 기본 잉크색). [bold]가 true면 굵게.
/// [bgColorValue]는 글자 뒤 형광펜(배경) 색(ARGB, null이면 배경 없음).
/// [x],[y]는 중심 비율(0~1로 가둠). 원본은 불변.
PageCanvas addTextLayer(
  PageCanvas canvas,
  String id,
  String text, {
  double x = 0.5,
  double y = 0.5,
  int? colorValue,
  bool bold = false,
  bool italic = false,
  bool underline = false,
  bool strike = false,
  bool shadow = false,
  int? bgColorValue,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return canvas;
  return addLayer(
    canvas,
    DecoLayer(
      id: id,
      kind: DecoKind.text,
      value: trimmed,
      x: clampUnit(x),
      y: clampUnit(y),
      colorValue: colorValue,
      bold: bold,
      italic: italic,
      underline: underline,
      strike: strike,
      shadow: shadow,
      bgColorValue: bgColorValue,
    ),
  );
}

/// 마스킹테이프(워시테이프) 레이어를 캔버스 맨 위에 추가한 새 캔버스를 반환한다.
/// [styleId]가 비어 있으면 잘못된 추가를 막기 위해 원본을 그대로 돌려준다.
/// 테이프는 살짝 기울여 붙이는 게 자연스러워 기본 각도([rotation])를 준다.
/// [x],[y]는 중심 비율(0~1로 가둠). 원본은 불변.
PageCanvas addTapeLayer(
  PageCanvas canvas,
  String id,
  String styleId, {
  double x = 0.5,
  double y = 0.3,
  double rotation = -8,
}) {
  if (styleId.trim().isEmpty) return canvas;
  return addLayer(
    canvas,
    DecoLayer(
      id: id,
      kind: DecoKind.tape,
      value: styleId,
      x: clampUnit(x),
      y: clampUnit(y),
      rotation: rotation,
    ),
  );
}

/// 레이어를 맨 위(topZ+1)에 추가한 새 캔버스를 반환한다. 원본은 불변.
PageCanvas addLayer(PageCanvas canvas, DecoLayer layer) => PageCanvas(
      version: canvas.version,
      paper: canvas.paper,
      paperColorValue: canvas.paperColorValue,
      layers: [...canvas.layers, layer.copyWith(z: canvas.topZ + 1)],
    );

/// id에 해당하는 레이어를 제거한 새 캔버스를 반환한다. 원본은 불변.
PageCanvas removeLayer(PageCanvas canvas, String id) => PageCanvas(
      version: canvas.version,
      paper: canvas.paper,
      paperColorValue: canvas.paperColorValue,
      layers: canvas.layers.where((l) => l.id != id).toList(),
    );

/// 같은 id의 레이어를 [updated]로 교체한 새 캔버스를 반환한다(없으면 그대로).
/// 위치·크기·회전 편집에 쓴다. 원본은 불변.
PageCanvas replaceLayer(PageCanvas canvas, DecoLayer updated) => PageCanvas(
      version: canvas.version,
      paper: canvas.paper,
      paperColorValue: canvas.paperColorValue,
      layers:
          canvas.layers.map((l) => l.id == updated.id ? updated : l).toList(),
    );

/// 속지(배경) 무늬만 [style]로 바꾼 새 캔버스를 반환한다(레이어는 그대로).
/// 원본은 불변.
PageCanvas setPaper(PageCanvas canvas, PaperStyle style) => PageCanvas(
      version: canvas.version,
      paper: style,
      paperColorValue: canvas.paperColorValue,
      layers: canvas.layers,
    );

/// 속지(배경) 바탕색만 [colorValue](ARGB, null이면 기본 크림)로 바꾼 새 캔버스를
/// 반환한다(무늬·레이어는 그대로). 원본은 불변.
PageCanvas setPaperColor(PageCanvas canvas, int? colorValue) => PageCanvas(
      version: canvas.version,
      paper: canvas.paper,
      paperColorValue: colorValue,
      layers: canvas.layers,
    );

/// id 레이어를 맨 위로 올린(z=topZ+1) 새 캔버스를 반환한다. 원본은 불변.
PageCanvas bringLayerToFront(PageCanvas canvas, String id) {
  final target = canvas.layers.where((l) => l.id == id);
  if (target.isEmpty || target.first.z == canvas.topZ) return canvas;
  return replaceLayer(canvas, target.first.copyWith(z: canvas.topZ + 1));
}

/// id 레이어를 맨 뒤로 내린(z=bottomZ-1) 새 캔버스를 반환한다. 이미 맨 뒤이거나
/// 없으면 원본 그대로. bringLayerToFront의 대칭. 원본은 불변.
PageCanvas sendLayerToBack(PageCanvas canvas, String id) {
  final target = canvas.layers.where((l) => l.id == id);
  if (target.isEmpty || target.first.z == canvas.bottomZ) return canvas;
  return replaceLayer(canvas, target.first.copyWith(z: canvas.bottomZ - 1));
}

/// id 레이어를 쌓임 순서에서 딱 한 칸 위로 올린 새 캔버스를 반환한다. 바로 위 이웃과
/// z를 맞바꿔 한 단계만 이동한다(맨 앞으로 보내기의 "한 칸"판). 이미 맨 위이거나 id가
/// 없으면 원본 그대로(동일 인스턴스). 원본은 불변.
PageCanvas stepLayerForward(PageCanvas canvas, String id) {
  final ordered = layersByZ(canvas);
  final idx = ordered.indexWhere((l) => l.id == id);
  if (idx < 0 || idx == ordered.length - 1) return canvas;
  final a = ordered[idx];
  final b = ordered[idx + 1];
  return replaceLayer(replaceLayer(canvas, a.copyWith(z: b.z)), b.copyWith(z: a.z));
}

/// id 레이어를 쌓임 순서에서 딱 한 칸 아래로 내린 새 캔버스를 반환한다. 바로 아래 이웃과
/// z를 맞바꿔 한 단계만 이동한다(맨 뒤로 보내기의 "한 칸"판, stepLayerForward의 대칭).
/// 이미 맨 아래이거나 id가 없으면 원본 그대로(동일 인스턴스). 원본은 불변.
PageCanvas stepLayerBackward(PageCanvas canvas, String id) {
  final ordered = layersByZ(canvas);
  final idx = ordered.indexWhere((l) => l.id == id);
  if (idx <= 0) return canvas;
  final a = ordered[idx];
  final b = ordered[idx - 1];
  return replaceLayer(replaceLayer(canvas, a.copyWith(z: b.z)), b.copyWith(z: a.z));
}

/// id 레이어의 회전을 0°로 되돌린(똑바로 세운) 새 캔버스를 반환한다. 위치·크기·z는
/// 그대로. 여러 번 돌리거나 기울여 붙인 테이프를 한 번에 반듯하게 펼 때 쓴다.
/// 이미 0°이거나 id가 없으면 원본 그대로. 원본은 불변.
PageCanvas straightenLayer(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.rotation == 0) return canvas;
  return replaceLayer(canvas, matches.first.copyWith(rotation: 0));
}

/// id 레이어를 시계방향으로 90° 돌린 새 캔버스를 반환한다. 결과 각도는 항상
/// 0~359° 범위로 정규화한다(음수·360° 이상 방지). 회전(+15° 미세)·똑바로(0°)의
/// 짝으로, 사진·테이프를 직각으로 빠르게 세울 때 쓴다. 위치·크기·z는 그대로.
/// id가 없으면 원본 그대로. 원본은 불변.
PageCanvas rotateLayerQuarter(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final next = ((l.rotation + 90) % 360 + 360) % 360;
  return replaceLayer(canvas, l.copyWith(rotation: next));
}

/// id 레이어의 회전을 [deltaDegrees]만큼 돌린 새 캔버스를 반환한다(결과는 0~359°로
/// 정규화, 음수·360° 이상 방지). 오른쪽(+15°)·왼쪽(-15°) 미세 회전 버튼이 공유한다.
/// 위치·크기·z는 그대로. id가 없으면 원본 그대로(동일 인스턴스). 원본은 불변.
PageCanvas stepLayerRotation(PageCanvas canvas, String id, double deltaDegrees) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final next = ((l.rotation + deltaDegrees) % 360 + 360) % 360;
  return replaceLayer(canvas, l.copyWith(rotation: next));
}

/// id 레이어의 회전을 가장 가까운 직각(0·90·180·270°)에 맞춰 반올림한 새 캔버스를
/// 반환한다(예 75°→90°, 30°→0°, 135°→180°). 먼저 0~359°로 정규화한 뒤 90° 눈금으로
/// 스냅해 다시 0~359°로 감싼다(315°→360→0). 45°처럼 정확히 중간이면 위 눈금으로
/// 올린다(→90°). 미세회전(±15°)으로 어정쩡하게 기운 레이어를 한 번에 반듯한 직각으로
/// 정돈할 때 쓴다(똑바로는 무조건 0°, 90°회전은 현재 각도에 +90°—이건 가장 가까운
/// 직각으로 스냅). 위치·크기·z는 그대로. 이미 직각 위(바뀔 게 없음)이거나 id가 없으면
/// 원본 그대로. 원본은 불변.
PageCanvas snapLayerRotation(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final norm = (l.rotation % 360 + 360) % 360;
  final snapped = ((norm / 90).round() * 90) % 360;
  if (snapped == l.rotation) return canvas;
  return replaceLayer(canvas, l.copyWith(rotation: snapped.toDouble()));
}

/// id 레이어의 크기를 기본(scale=1.0)으로 되돌린 새 캔버스를 반환한다. 위치·회전·z는
/// 그대로. 여러 번 키우거나 줄인 레이어를 한 번에 원래 크기로 되돌릴 때 쓴다.
/// 이미 1.0이거나 id가 없으면 원본 그대로. 원본은 불변.
PageCanvas resetLayerScale(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.scale == 1.0) return canvas;
  return replaceLayer(canvas, matches.first.copyWith(scale: 1.0));
}

/// 캔버스에서 허용하는 레이어 크기(scale) 범위. 너무 작아 사라지거나 너무 커져
/// 페이지를 벗어나는 것을 막는다. 작게/크게 버튼이 공유한다.
const double kMinLayerScale = 0.4;
const double kMaxLayerScale = 4.0;

/// id 레이어의 크기를 [delta]만큼 키우거나 줄인 새 캔버스를 반환한다(작게 -,
/// 크게 +). 결과는 [kMinLayerScale]~[kMaxLayerScale]로 가둔다. 위치·회전·z는
/// 그대로. id가 없거나 가둔 뒤 크기가 그대로면(한계) 원본 그대로(동일 인스턴스).
/// 원본은 불변.
PageCanvas stepLayerScale(PageCanvas canvas, String id, double delta) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final next = (l.scale + delta).clamp(kMinLayerScale, kMaxLayerScale);
  if (next == l.scale) return canvas;
  return replaceLayer(canvas, l.copyWith(scale: next));
}

/// 글자 자간을 조절할 때 허용하는 단계 범위. 너무 좁혀 겹치거나 너무 벌려
/// 흩어지는 것을 막는다. 자간-/자간+ 버튼이 공유한다(글자 크기에 비례해 렌더).
const double kMinLetterSpacing = -3.0;
const double kMaxLetterSpacing = 10.0;

/// id 레이어의 글자 자간을 [delta]만큼 넓히거나 좁힌 새 캔버스를 반환한다
/// (자간- -, 자간+ +). 결과는 [kMinLetterSpacing]~[kMaxLetterSpacing]로 가둔다.
/// 위치·크기·회전·z·다른 글자 속성은 그대로. id가 없거나 가둔 뒤 값이 그대로면
/// (한계) 원본 그대로(동일 인스턴스). 글자 아닌 레이어에 써도 무해하다(렌더에
/// 반영 안 됨). 원본은 불변.
PageCanvas stepLayerLetterSpacing(PageCanvas canvas, String id, double delta) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final next =
      (l.letterSpacing + delta).clamp(kMinLetterSpacing, kMaxLetterSpacing);
  if (next == l.letterSpacing) return canvas;
  return replaceLayer(canvas, l.copyWith(letterSpacing: next));
}

/// id 레이어의 *변형*을 한 번에 기본값으로 되돌린 새 캔버스를 반환한다.
/// 크기(scale→1.0)·회전(rotation→0)·좌우 뒤집기(flipX→false)·상하 뒤집기
/// (flipY→false)·투명도(opacity→1.0)를 모두 초기화한다. 위치(x·y)·z·글자 속성
/// (색·굵기·기울임·밑줄·형광펜)은 그대로 둔다. 원래크기·똑바로·또렷하게를 따로
/// 누르지 않고 한 번에 정리할 때 쓴다. 이미 전부 기본값이거나 id가 없으면 원본
/// 그대로(동일 인스턴스). 원본은 불변.
PageCanvas resetLayerTransform(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  if (l.scale == 1.0 &&
      l.rotation == 0.0 &&
      !l.flipX &&
      !l.flipY &&
      l.opacity == 1.0) {
    return canvas;
  }
  return replaceLayer(
    canvas,
    l.copyWith(
      scale: 1.0,
      rotation: 0.0,
      flipX: false,
      flipY: false,
      opacity: 1.0,
    ),
  );
}

/// id 레이어를 [dx],[dy] 만큼 미세하게 옮긴 새 캔버스를 반환한다(작은 캔버스에서
/// 드래그로는 정밀하게 못 놓을 때 화살표로 한 칸씩). 위치는 0~1로 가둔다. 크기·회전·
/// z는 그대로. id가 없거나 가둔 뒤 위치가 그대로면(가장자리) 원본 그대로. 원본은 불변.
PageCanvas nudgeLayer(PageCanvas canvas, String id, double dx, double dy) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final nx = clampUnit(l.x + dx);
  final ny = clampUnit(l.y + dy);
  if (nx == l.x && ny == l.y) return canvas;
  return replaceLayer(canvas, l.copyWith(x: nx, y: ny));
}

/// id 레이어를 똑같이 복제한 새 캔버스를 반환한다(같은 스티커/테이프/글자를 도장처럼
/// 여러 번 찍을 때). 복제본은 [newId]를 달고 살짝 어긋난 위치([dx],[dy] 만큼, 0~1로
/// 가둠)에 맨 위로 얹힌다. 색·굵기·형광펜·크기·회전 등 모든 속성은 그대로 복사된다.
/// id가 없으면 원본 그대로. 원본은 불변.
PageCanvas duplicateLayer(
  PageCanvas canvas,
  String id,
  String newId, {
  double dx = 0.04,
  double dy = 0.04,
}) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final src = matches.first;
  return addLayer(
    canvas,
    DecoLayer(
      id: newId,
      kind: src.kind,
      value: src.value,
      x: clampUnit(src.x + dx),
      y: clampUnit(src.y + dy),
      scale: src.scale,
      rotation: src.rotation,
      colorValue: src.colorValue,
      bold: src.bold,
      bgColorValue: src.bgColorValue,
      flipX: src.flipX,
      flipY: src.flipY,
      opacity: src.opacity,
      italic: src.italic,
      underline: src.underline,
      strike: src.strike,
      shadow: src.shadow,
      letterSpacing: src.letterSpacing,
    ),
  );
}

/// id 레이어의 불투명도를 [delta]만큼 조절(0.2~1.0로 가둠)한 새 캔버스를 반환한다.
/// 흐리게(-)·진하게(+) 버튼이 쓴다. 이미 한계라 값이 그대로면 원본(동일 인스턴스),
/// id가 없어도 원본 그대로. 위치·크기·회전·z 등은 보존. 원본은 불변.
PageCanvas stepLayerOpacity(PageCanvas canvas, String id, double delta) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  final next = (l.opacity + delta).clamp(0.2, 1.0);
  if (next == l.opacity) return canvas;
  return replaceLayer(canvas, l.copyWith(opacity: next));
}

/// id 레이어의 투명도를 완전 불투명(1.0)으로 되돌린 새 캔버스를 반환한다.
/// resetLayerScale의 투명도판—여러 번 흐리게 한 레이어를 한 번에 또렷하게. 위치·
/// 크기·회전·z는 그대로. 이미 1.0이거나 id가 없으면 원본 그대로(동일 인스턴스).
/// 원본은 불변.
PageCanvas resetLayerOpacity(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.opacity == 1.0) return canvas;
  return replaceLayer(canvas, matches.first.copyWith(opacity: 1.0));
}

/// stepLayerLetterSpacing의 리셋판—자간을 여러 번 넓히거나 좁힌 글자를 한 번에
/// 기본 간격(0.0)으로 되돌린다. 위치·크기·회전·z·다른 글자 속성은 그대로. 이미
/// 0.0이거나 id가 없으면 원본 그대로(동일 인스턴스). 원본은 불변.
PageCanvas resetLayerLetterSpacing(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.letterSpacing == 0.0) return canvas;
  return replaceLayer(canvas, matches.first.copyWith(letterSpacing: 0.0));
}

/// id 레이어의 좌우 뒤집힘(거울상)을 토글한 새 캔버스를 반환한다. 위치·크기·회전·z는
/// 그대로. 방향이 있는 스티커·사진을 반대로 돌려 배치할 때 쓴다. id가 없으면 원본
/// 그대로. 원본은 불변.
PageCanvas flipLayerX(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  return replaceLayer(canvas, l.copyWith(flipX: !l.flipX));
}

/// id 레이어의 위아래 뒤집힘을 토글한 새 캔버스를 반환한다. 위치·크기·회전·z는
/// 그대로. flipLayerX의 세로판(둘 다 켜면 180° 돌린 것과 같다). id가 없으면 원본
/// 그대로. 원본은 불변.
PageCanvas flipLayerY(PageCanvas canvas, String id) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty) return canvas;
  final l = matches.first;
  return replaceLayer(canvas, l.copyWith(flipY: !l.flipY));
}

/// 글자 레이어의 문구·잉크 색·굵기·형광펜 배경을 통째로 갈아끼운 새 캔버스를
/// 반환한다(위치·크기·회전·z는 그대로). 오타 수정 등 이미 올린 글자를 고칠 때 쓴다.
/// [bgColorValue]에 null을 주면 형광펜을 없앨 수 있다(copyWith로는 불가). [text]가
/// 공백이면 잘못된 편집을 막기 위해 원본 그대로. id가 없거나 글자 레이어가 아니면
/// 원본 그대로. 원본은 불변.
PageCanvas updateTextLayer(
  PageCanvas canvas,
  String id,
  String text, {
  int? colorValue,
  bool bold = false,
  bool italic = false,
  bool underline = false,
  bool strike = false,
  bool shadow = false,
  int? bgColorValue,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return canvas;
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.kind != DecoKind.text) return canvas;
  final src = matches.first;
  return replaceLayer(
    canvas,
    DecoLayer(
      id: src.id,
      kind: DecoKind.text,
      value: trimmed,
      x: src.x,
      y: src.y,
      scale: src.scale,
      rotation: src.rotation,
      z: src.z,
      colorValue: colorValue,
      bold: bold,
      italic: italic,
      underline: underline,
      strike: strike,
      shadow: shadow,
      bgColorValue: bgColorValue,
    ),
  );
}

/// 가장 최근에 올린 레이어(리스트의 마지막) 하나를 지운 새 캔버스를 반환한다.
/// 방금 올린 스티커·글자·사진·테이프를 실행 취소처럼 한 번에 무를 때 쓴다.
/// z(쌓임 순서)가 아니라 **추가 순서** 기준이라 맨 앞/맨 뒤 보내기와 무관하게
/// "방금 올린 것"을 지운다(레이어 조작 함수들이 모두 리스트 순서를 보존하므로
/// layers.last가 항상 가장 최근 추가분). 비어 있으면 원본 그대로. 원본은 불변.
PageCanvas removeLastLayer(PageCanvas canvas) {
  if (canvas.layers.isEmpty) return canvas;
  return removeLayer(canvas, canvas.layers.last.id);
}

/// [kind]에 해당하는 레이어를 모두 지운 새 캔버스를 반환한다(예: 테이프만 한 번에
/// 정리, 스티커는 그대로 둠). 해당 종류가 하나도 없으면 원본 그대로(동일 인스턴스).
/// 속지 무늬·바탕색과 다른 종류 레이어는 보존. 원본은 불변.
PageCanvas removeLayersOfKind(PageCanvas canvas, DecoKind kind) {
  if (!canvas.layers.any((l) => l.kind == kind)) return canvas;
  return PageCanvas(
    version: canvas.version,
    paper: canvas.paper,
    paperColorValue: canvas.paperColorValue,
    layers: canvas.layers.where((l) => l.kind != kind).toList(),
  );
}
