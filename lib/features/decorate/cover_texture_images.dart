import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cover_texture.dart';

/// 표지 재질(가죽/크라프트/패브릭)의 실사 텍스처 이미지를 비동기로 로드·캐시한다.
///
/// 에셋은 흑백(휘도) 심리스 타일이라 `BlendMode.multiply`로 어떤 표지 색에도
/// 색은 유지한 채 결(요철)만 입힐 수 있다. 이미지가 로드되면 [notifyListeners]로
/// 그리는 페인터를 다시 그리게 한다(페인터는 이 인스턴스를 repaint 리스너로 씀).
class CoverTextureImages extends ChangeNotifier {
  CoverTextureImages._();
  static final CoverTextureImages instance = CoverTextureImages._();

  /// 재질 id → 에셋 경로('none'은 없음=질감 안 입힘).
  static const Map<String, String> assets = {
    'leather': 'assets/textures/leather.jpg',
    'kraft': 'assets/textures/kraft.jpg',
    'fabric': 'assets/textures/fabric.jpg',
    'cork': 'assets/textures/cork.jpg',
    'wood': 'assets/textures/wood.jpg',
  };

  final Map<String, ui.Image> _cache = {};
  final Set<String> _loading = {};

  /// 캐시된 이미지 반환. 아직 없으면 null을 주고 비동기 로드를 시작한다.
  ui.Image? imageFor(String id) {
    final key = normalizeCoverTexture(id);
    final asset = assets[key];
    if (asset == null) return null; // none.
    final cached = _cache[key];
    if (cached != null) return cached;
    _load(key, asset);
    return null;
  }

  Future<void> _load(String key, String asset) async {
    if (_loading.contains(key)) return;
    _loading.add(key);
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _cache[key] = frame.image;
      notifyListeners();
    } finally {
      _loading.remove(key);
    }
  }
}
