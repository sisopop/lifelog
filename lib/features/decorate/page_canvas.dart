// 기록 페이지(내지) 꾸미기의 핵심 데이터 모델.
//
// 표지 꾸미기(cover_*)가 일기장 *겉표지*를 꾸민다면, 이 파일은 한 기록 *안쪽
// 페이지* 위에 스티커·글상자·사진을 자유롭게 배치하는 "캔버스" 문서를 표현한다.
//
// 기존 본문(DiaryEntry.content 순수 텍스트)·검색·통계·타임라인 미리보기를
// 깨지 않도록 **추가형**으로 설계했다. 캔버스는 별도의 JSON 문자열로 직렬화돼
// 본문과 나란히 저장되며, 본문 텍스트는 그대로 살아있다(캔버스가 비면 종전과
// 똑같이 동작). 좌표는 페이지 크기에 무관하도록 0~1 비율로 저장한다.

import 'dart:convert';

/// 페이지 위에 놓을 수 있는 요소의 종류.
/// tape=마스킹테이프(워시테이프) 색 조각.
enum DecoKind { text, sticker, photo, tape }

DecoKind _kindFromName(String? name) => DecoKind.values.firstWhere(
      (k) => k.name == name,
      orElse: () => DecoKind.sticker,
    );

/// 페이지 속지(배경) 무늬. plain=무지, lined=가로줄, grid=모눈, dotted=도트.
enum PaperStyle { plain, lined, grid, dotted }

PaperStyle _paperFromName(String? name) => PaperStyle.values.firstWhere(
      (p) => p.name == name,
      orElse: () => PaperStyle.plain,
    );

/// 0~1 범위로 가둔다(페이지 밖으로 중심이 빠져나가지 않도록).
double clampUnit(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// 페이지 위 단일 요소. [x],[y]는 요소 *중심*의 페이지 대비 비율(0~1)이라
/// 어떤 크기로 렌더하든 같은 배치가 재현된다. [scale]은 기본 크기 배수,
/// [rotation]은 도(degree) 단위 회전, [z]는 쌓임 순서(클수록 위).
class DecoLayer {
  const DecoLayer({
    required this.id,
    required this.kind,
    required this.value,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.z = 0,
  });

  final String id;
  final DecoKind kind;

  /// text → 글 내용, sticker → 이모지/스티커 키, photo → 미디어 URL,
  /// tape → 테이프 스타일 id(색은 washi_tape_catalog에서 매핑).
  final String value;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int z;

  DecoLayer copyWith({
    DecoKind? kind,
    String? value,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? z,
  }) =>
      DecoLayer(
        id: id,
        kind: kind ?? this.kind,
        value: value ?? this.value,
        x: x ?? this.x,
        y: y ?? this.y,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
        z: z ?? this.z,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'value': value,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        'z': z,
      };

  /// 관대한 파서: 누락/타입오류 필드는 기본값으로 채운다(저장본 깨짐 방지).
  factory DecoLayer.fromJson(Map<String, dynamic> json) => DecoLayer(
        id: (json['id'] as String?) ?? '',
        kind: _kindFromName(json['kind'] as String?),
        value: (json['value'] as String?) ?? '',
        x: clampUnit(_toDouble(json['x'], 0.5)),
        y: clampUnit(_toDouble(json['y'], 0.5)),
        scale: _toDouble(json['scale'], 1.0),
        rotation: _toDouble(json['rotation'], 0.0),
        z: (json['z'] as num?)?.toInt() ?? 0,
      );
}

double _toDouble(Object? v, double fallback) =>
    v is num ? v.toDouble() : fallback;

/// 한 기록 페이지의 꾸미기 문서: 레이어 묶음 + 속지 무늬 + 포맷 버전.
class PageCanvas {
  const PageCanvas({
    this.layers = const [],
    this.paper = PaperStyle.plain,
    this.version = 1,
  });

  final List<DecoLayer> layers;

  /// 속지(배경) 무늬. 레이어가 없어도 배경만 골라 꾸밀 수 있다.
  final PaperStyle paper;
  final int version;

  bool get isEmpty => layers.isEmpty;

  /// 현재 가장 높은 z(없으면 -1). 새 레이어를 맨 위에 얹을 때 쓴다.
  int get topZ =>
      layers.isEmpty ? -1 : layers.map((l) => l.z).reduce((a, b) => a > b ? a : b);

  /// 현재 가장 낮은 z(없으면 0). 레이어를 맨 뒤로 내릴 때 쓴다.
  int get bottomZ =>
      layers.isEmpty ? 0 : layers.map((l) => l.z).reduce((a, b) => a < b ? a : b);

  Map<String, dynamic> toJson() => {
        'version': version,
        'paper': paper.name,
        'layers': layers.map((l) => l.toJson()).toList(),
      };

  factory PageCanvas.fromJson(Map<String, dynamic> json) {
    final raw = json['layers'];
    final layers = raw is List
        ? raw
            .whereType<Map>()
            .map((m) => DecoLayer.fromJson(m.cast<String, dynamic>()))
            .toList()
        : <DecoLayer>[];
    return PageCanvas(
      layers: layers,
      paper: _paperFromName(json['paper'] as String?),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }
}

/// 캔버스를 저장용 JSON 문자열로 직렬화한다.
String encodePageCanvas(PageCanvas canvas) => jsonEncode(canvas.toJson());

/// 저장된 문자열을 캔버스로 복원한다. null/빈/깨진 입력은 빈 캔버스로 폴백해
/// 절대 예외를 던지지 않는다(기존 텍스트 전용 기록과 호환).
PageCanvas decodePageCanvas(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const PageCanvas();
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return PageCanvas.fromJson(decoded);
  } catch (_) {
    // 깨진 JSON → 빈 캔버스
  }
  return const PageCanvas();
}

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
/// [x],[y]는 중심 비율(0~1로 가둠). 원본은 불변.
PageCanvas addTextLayer(
  PageCanvas canvas,
  String id,
  String text, {
  double x = 0.5,
  double y = 0.5,
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
      layers: [...canvas.layers, layer.copyWith(z: canvas.topZ + 1)],
    );

/// id에 해당하는 레이어를 제거한 새 캔버스를 반환한다. 원본은 불변.
PageCanvas removeLayer(PageCanvas canvas, String id) => PageCanvas(
      version: canvas.version,
      paper: canvas.paper,
      layers: canvas.layers.where((l) => l.id != id).toList(),
    );

/// 같은 id의 레이어를 [updated]로 교체한 새 캔버스를 반환한다(없으면 그대로).
/// 위치·크기·회전 편집에 쓴다. 원본은 불변.
PageCanvas replaceLayer(PageCanvas canvas, DecoLayer updated) => PageCanvas(
      version: canvas.version,
      paper: canvas.paper,
      layers:
          canvas.layers.map((l) => l.id == updated.id ? updated : l).toList(),
    );

/// 속지(배경) 무늬만 [style]로 바꾼 새 캔버스를 반환한다(레이어는 그대로).
/// 원본은 불변.
PageCanvas setPaper(PageCanvas canvas, PaperStyle style) => PageCanvas(
      version: canvas.version,
      paper: style,
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

/// 캔버스 구성 요약 문구(예: "스티커 2 · 사진 1"). 레이어 종류별 개수를 세어
/// 0인 종류는 빼고 이어 붙인다. 레이어가 하나도 없으면 null(무늬만 있는 경우
/// 포함). 편집기를 열지 않고도 무엇이 올라가 있는지 한눈에 보여줄 때 쓴다.
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
    if (stickers > 0) '스티커 $stickers',
    if (photos > 0) '사진 $photos',
    if (tapes > 0) '테이프 $tapes',
    if (texts > 0) '글자 $texts',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// 그리기 순서(아래→위)대로 정렬한 레이어 목록. z 동률은 원래 순서 유지.
List<DecoLayer> layersByZ(PageCanvas canvas) {
  final sorted = [...canvas.layers];
  sorted.sort((a, b) => a.z.compareTo(b.z));
  return sorted;
}
