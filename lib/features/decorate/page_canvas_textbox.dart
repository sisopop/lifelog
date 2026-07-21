part of 'page_canvas.dart';

// 텍스트박스(사용자가 크기를 정한 빈 상자에 직접 글을 쓰는 요소) 전용 순수 연산.
//
// 일반 "글자 넣기"(addTextLayer/updateTextLayer)와 달리, 텍스트박스는 ①빈 값으로도
// 만들 수 있고(먼저 상자를 놓고 그 안에 나중에 입력), ②페이지 대비 가로·세로 크기
// (boxW·boxH, 0~1 비율)를 사용자가 드래그로 조절한다. 크기·글 조작을 여기 모았다
// (page_canvas_ops.dart가 500줄 상한에 닿아 별도 part로 분리, 라이브러리·import는 동일).
// 모두 원본 불변, 바뀔 게 없으면 같은 인스턴스를 그대로 돌려준다.

/// 새 텍스트박스의 기본 크기(페이지 대비 비율). 폭 절반·높이 1/5로, 처음 만들었을 때
/// 한두 줄 쓰기 적당한 상자가 나온다. 사용자가 이후 드래그로 키우거나 줄인다.
const double kDefaultTextBoxW = 0.5;
const double kDefaultTextBoxH = 0.18;

/// 텍스트박스 크기(boxW·boxH) 허용 범위. 너무 작아 글을 못 쓰거나 페이지를 벗어나는
/// 것을 막는다. 리사이즈 드래그가 이 범위로 가둔다.
const double kMinTextBoxSize = 0.12;
const double kMaxTextBoxSize = 1.0;

double _clampBox(double v) => v < kMinTextBoxSize
    ? kMinTextBoxSize
    : (v > kMaxTextBoxSize ? kMaxTextBoxSize : v);

/// 빈 텍스트박스를 캔버스 맨 위에 추가한 새 캔버스를 반환한다. 글자 넣기와 달리 값이
/// 비어 있어도(사용자가 상자만 먼저 놓고 나중에 입력) 정상 추가한다. [x],[y]는 중심
/// 비율(0~1로 가둠), [boxW]·[boxH]는 페이지 대비 크기(범위로 가둠). 원본은 불변.
PageCanvas addTextBoxLayer(
  PageCanvas canvas,
  String id, {
  String text = '',
  double x = 0.5,
  double y = 0.5,
  double boxW = kDefaultTextBoxW,
  double boxH = kDefaultTextBoxH,
  int? colorValue,
}) =>
    addLayer(
      canvas,
      DecoLayer(
        id: id,
        kind: DecoKind.textbox,
        value: text,
        x: clampUnit(x),
        y: clampUnit(y),
        boxW: _clampBox(boxW),
        boxH: _clampBox(boxH),
        colorValue: colorValue,
      ),
    );

/// id 텍스트박스의 **가로 폭**을 [boxW](페이지 대비 비율)로 바꾼 새 캔버스를 반환한다.
/// **왼쪽 변을 고정**하기 위해 폭이 늘어난 만큼(dw)의 절반만큼 중심 x도 오른쪽으로 옮겨,
/// 우하 손잡이 드래그 시 왼쪽 변은 그 자리에 두고 오른쪽 변만 손가락을 따라 벌어진다.
/// 세로·글·회전·z는 그대로. 값은 [kMinTextBoxSize]~[kMaxTextBoxSize]로 가둔다. id가 없거나
/// 텍스트박스가 아니거나 가둔 뒤 폭이 그대로면 원본 그대로. 원본은 불변.
PageCanvas resizeTextBoxWidth(PageCanvas canvas, String id, double boxW) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.kind != DecoKind.textbox) return canvas;
  final l = matches.first;
  final nw = _clampBox(boxW);
  final ow = l.boxW ?? kDefaultTextBoxW;
  if (nw == ow) return canvas;
  return replaceLayer(
      canvas, l.copyWith(boxW: nw, x: clampUnit(l.x + (nw - ow) / 2)));
}

/// id 텍스트박스의 **세로 높이**를 [boxH](페이지 대비 비율)로 바꾼 새 캔버스를 반환한다.
/// **위쪽 변을 고정**하기 위해 높이가 늘어난 만큼(dh)의 절반만큼 중심 y도 아래로 옮겨,
/// 우하 손잡이 드래그 시 위쪽 변은 그 자리에 두고 아래쪽 변만 손가락을 따라 내려간다.
/// 가로·글·회전·z는 그대로. 값은 [kMinTextBoxSize]~[kMaxTextBoxSize]로 가둔다. id가 없거나
/// 텍스트박스가 아니거나 가둔 뒤 높이가 그대로면 원본 그대로. 원본은 불변.
PageCanvas resizeTextBoxHeight(PageCanvas canvas, String id, double boxH) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.kind != DecoKind.textbox) return canvas;
  final l = matches.first;
  final nh = _clampBox(boxH);
  final oh = l.boxH ?? kDefaultTextBoxH;
  if (nh == oh) return canvas;
  return replaceLayer(
      canvas, l.copyWith(boxH: nh, y: clampUnit(l.y + (nh - oh) / 2)));
}

/// id 텍스트박스 안의 글을 [text]로 바꾼 새 캔버스를 반환한다. 글자 넣기(updateTextLayer)
/// 와 달리 빈 값도 허용한다(상자는 남기고 글만 지울 수 있게). 크기·위치·회전·z는 그대로.
/// id가 없거나 텍스트박스가 아니거나 값이 그대로면 원본 그대로. 원본은 불변.
PageCanvas setTextBoxText(PageCanvas canvas, String id, String text) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.kind != DecoKind.textbox) return canvas;
  final l = matches.first;
  if (text == l.value) return canvas;
  return replaceLayer(canvas, l.copyWith(value: text));
}

/// id 텍스트박스의 **부분 서식(리치텍스트)**를 [richValue](Quill Delta JSON)로 바꾸고,
/// 검색·통계·미리보기용 서식 없는 평문 [plain]을 함께 저장한 새 캔버스를 반환한다.
/// 리치텍스트 편집기가 글을 바꿀 때마다 부른다. 값이 둘 다 그대로면 원본 그대로.
/// id가 없거나 텍스트박스가 아니어도 원본 그대로. 원본은 불변.
PageCanvas setTextBoxRich(
    PageCanvas canvas, String id, String plain, String richValue) {
  final matches = canvas.layers.where((l) => l.id == id);
  if (matches.isEmpty || matches.first.kind != DecoKind.textbox) return canvas;
  final l = matches.first;
  if (plain == l.value && richValue == l.richValue) return canvas;
  return replaceLayer(canvas, l.copyWith(value: plain, richValue: richValue));
}
