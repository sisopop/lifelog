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

part 'page_canvas_ops.dart';

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
    this.colorValue,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.bgColorValue,
    this.flipX = false,
    this.flipY = false,
    this.opacity = 1.0,
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

  /// 글자 색(ARGB 정수). null이면 기본 잉크색으로 그린다. 지금은 text 레이어에만
  /// 쓰인다(옛 저장본·다른 종류는 null이라 종전과 동일).
  final int? colorValue;

  /// 글자를 굵게 그릴지. text 레이어에만 쓰인다(기본 false=보통 굵기, 옛 저장본
  /// 호환). true면 [FontWeight.w700]로 렌더.
  final bool bold;

  /// 글자를 기울여(이탤릭) 그릴지. text 레이어에만 쓰인다(기본 false=곧은 글자,
  /// 옛 저장본 호환). true면 [FontStyle.italic]로 렌더. bold와 독립.
  final bool italic;

  /// 글자에 밑줄을 그을지. text 레이어에만 쓰인다(기본 false=밑줄 없음, 옛 저장본
  /// 호환). true면 [TextDecoration.underline]로 렌더. bold·italic과 독립.
  final bool underline;

  /// 글자 뒤에 깔리는 형광펜(배경) 색(ARGB 정수). null이면 배경 없음. text
  /// 레이어에만 쓰인다(옛 저장본·다른 종류는 null이라 종전과 동일).
  final int? bgColorValue;

  /// 좌우로 뒤집어(거울상) 그릴지. 기본 false(옛 저장본 호환). 스티커·사진·테이프·
  /// 글자 어디에나 적용된다(렌더는 decoLayerContent가 처리).
  final bool flipX;

  /// 위아래로 뒤집어 그릴지. 기본 false(옛 저장본 호환). flipX와 독립이라 둘 다
  /// true면 180° 돌린 것과 같다(렌더는 decoLayerContent가 처리).
  final bool flipY;

  /// 불투명도(0~1). 기본 1.0=불투명. 낮출수록 배경·아래 레이어가 비쳐 은은한
  /// 느낌을 준다(옛 저장본은 1.0이라 종전과 동일). 스티커·사진·테이프·글자
  /// 어디에나 적용된다(렌더는 decoLayerContent가 처리).
  final double opacity;

  DecoLayer copyWith({
    DecoKind? kind,
    String? value,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? z,
    int? colorValue,
    bool? bold,
    bool? italic,
    bool? underline,
    int? bgColorValue,
    bool? flipX,
    bool? flipY,
    double? opacity,
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
        colorValue: colorValue ?? this.colorValue,
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        bgColorValue: bgColorValue ?? this.bgColorValue,
        flipX: flipX ?? this.flipX,
        flipY: flipY ?? this.flipY,
        opacity: opacity ?? this.opacity,
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
        // 색이 없으면 아예 안 적어 옛 저장본과 바이트가 같게 유지한다.
        if (colorValue != null) 'color': colorValue,
        // 굵게가 아니면(기본) 키를 빼서 옛 저장본과 바이트가 같게 유지한다.
        if (bold) 'bold': true,
        // 기울임이 아니면(기본) 키를 빼서 옛 저장본과 바이트가 같게 유지한다.
        if (italic) 'italic': true,
        // 밑줄이 아니면(기본) 키를 빼서 옛 저장본과 바이트가 같게 유지한다.
        if (underline) 'underline': true,
        // 배경이 없으면(기본) 키를 빼서 옛 저장본과 바이트가 같게 유지한다.
        if (bgColorValue != null) 'bg': bgColorValue,
        // 뒤집지 않았으면(기본) 키를 빼서 옛 저장본과 바이트가 같게 유지한다.
        if (flipX) 'flipX': true,
        if (flipY) 'flipY': true,
        // 불투명(기본 1.0)이면 키를 빼서 옛 저장본과 바이트가 같게 유지한다.
        if (opacity != 1.0) 'opacity': opacity,
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
        colorValue: (json['color'] as num?)?.toInt(),
        bold: json['bold'] == true,
        italic: json['italic'] == true,
        underline: json['underline'] == true,
        bgColorValue: (json['bg'] as num?)?.toInt(),
        flipX: json['flipX'] == true,
        flipY: json['flipY'] == true,
        opacity: _toDouble(json['opacity'], 1.0),
      );
}

double _toDouble(Object? v, double fallback) =>
    v is num ? v.toDouble() : fallback;

/// 한 기록 페이지의 꾸미기 문서: 레이어 묶음 + 속지 무늬 + 포맷 버전.
class PageCanvas {
  const PageCanvas({
    this.layers = const [],
    this.paper = PaperStyle.plain,
    this.paperColorValue,
    this.version = 1,
  });

  final List<DecoLayer> layers;

  /// 속지(배경) 무늬. 레이어가 없어도 배경만 골라 꾸밀 수 있다.
  final PaperStyle paper;

  /// 속지(배경) 바탕색(ARGB 정수). null이면 기본 크림색. 무늬(paper)와 별개로
  /// 종이 자체의 색을 고른다(옛 저장본은 null이라 종전과 동일).
  final int? paperColorValue;
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
        // 바탕색이 없으면(기본 크림) 키를 빼서 옛 저장본과 바이트가 같게 유지한다.
        if (paperColorValue != null) 'paperColor': paperColorValue,
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
      paperColorValue: (json['paperColor'] as num?)?.toInt(),
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

