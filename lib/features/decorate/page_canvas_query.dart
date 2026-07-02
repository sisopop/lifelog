// 페이지 캔버스의 *읽기 전용* 조회 헬퍼 모음.
//
// page_canvas_ops.dart가 상한(500줄)에 닿아, 캔버스를 바꾸지 않고 정보만 뽑아내는
// 순수 함수(요약 문구·z 정렬·선택 순회)를 이 part로 분리했다. 같은 라이브러리의
// part라 import 변경 없이 그대로 쓰인다.
part of 'page_canvas.dart';

/// 캔버스 구성 요약 문구(예: "모눈 속지 · 스티커 2 · 사진 1"). 속지 무늬(무지 제외)와
/// 바탕색을 앞에 두고, 이어서 레이어 종류별 개수를 0인 종류는 빼고 붙인다. 아무것도
/// 없으면(레이어 0 · 무지 · 바탕색 없음) null. 편집기를 열지 않고도 무엇이 올라가
/// 있는지 한눈에 보여줄 때 쓴다.
String? pageCanvasSummary(PageCanvas canvas) {
  var stickers = 0, photos = 0, texts = 0, tapes = 0;
  for (final l in canvas.layers) {
    switch (l.kind) {
      case DecoKind.sticker:
        stickers++;
      case DecoKind.photo:
        photos++;
      case DecoKind.text:
        texts++;
      case DecoKind.tape:
        tapes++;
    }
  }
  final parts = <String>[
    if (canvas.paper != PaperStyle.plain) '${_paperStyleLabel(canvas.paper)} 속지',
    if (canvas.paperColorValue != null) '바탕색',
    if (stickers > 0) '스티커 $stickers',
    if (photos > 0) '사진 $photos',
    if (tapes > 0) '테이프 $tapes',
    if (texts > 0) '글자 $texts',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// 속지 무늬의 한글 라벨(요약 문구용). 무지는 요약에서 생략되므로 호출되지 않지만
/// switch 완전성을 위해 값을 둔다.
String _paperStyleLabel(PaperStyle style) {
  switch (style) {
    case PaperStyle.plain:
      return '무지';
    case PaperStyle.lined:
      return '줄';
    case PaperStyle.grid:
      return '모눈';
    case PaperStyle.dotted:
      return '도트';
  }
}

/// 그리기 순서(아래→위)대로 정렬한 레이어 목록. z 동률은 원래 순서 유지.
List<DecoLayer> layersByZ(PageCanvas canvas) {
  final sorted = [...canvas.layers];
  sorted.sort((a, b) => a.z.compareTo(b.z));
  return sorted;
}

/// 쌓임 순서(z, 아래→위)를 따라 [currentId] *다음* 레이어의 id를 돌려준다. 맨 위
/// 다음은 다시 맨 아래로 순환한다. 겹쳐 놓아 탭으로 고르기 힘든 아래 레이어를
/// 차례로 선택할 때 쓴다. 규칙:
/// - 레이어가 없으면 null.
/// - [currentId]가 null이거나 캔버스에 없으면 맨 아래(z 최소) 레이어 id.
/// - 레이어가 하나뿐이면 그 하나의 id(제자리).
String? nextLayerId(PageCanvas canvas, String? currentId) {
  final ordered = layersByZ(canvas);
  if (ordered.isEmpty) return null;
  final i = ordered.indexWhere((l) => l.id == currentId);
  if (i < 0) return ordered.first.id;
  return ordered[(i + 1) % ordered.length].id;
}

/// 쌓임 순서(z, 아래→위)를 따라 [currentId] *이전*(한 칸 아래) 레이어의 id를
/// 돌려준다. [nextLayerId]의 대칭으로, 맨 아래 이전은 다시 맨 위로 순환한다.
/// "다음 레이어"로 지나쳤을 때 되돌아올 때 쓴다. 규칙:
/// - 레이어가 없으면 null.
/// - [currentId]가 null이거나 캔버스에 없으면 맨 위(z 최대) 레이어 id.
/// - 레이어가 하나뿐이면 그 하나의 id(제자리).
String? previousLayerId(PageCanvas canvas, String? currentId) {
  final ordered = layersByZ(canvas);
  if (ordered.isEmpty) return null;
  final i = ordered.indexWhere((l) => l.id == currentId);
  if (i < 0) return ordered.last.id;
  return ordered[(i - 1 + ordered.length) % ordered.length].id;
}
