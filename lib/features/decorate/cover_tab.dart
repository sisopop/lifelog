/// 다꾸 표지 우측 인덱스 탭(색깔 탭)의 순수 소스 오브 트루스.
///
/// 탭은 속지에 끼워져 표지 '우측' 경계 밖으로 여러 개가 살짝 삐져나온 모습이다
/// (책갈피=아래, 클립=위와 같은 "표지 밖 삐져나옴" 원리의 우측판).
/// 색상 조합은 painter가 id별로 정의하므로 여기엔 색상 맵을 두지 않는다
/// (모서리/밴드 순수 파일과 동일한 스타일 기반 구성).
library;

/// 기본값 = 탭 없음.
const String kDefaultCoverTab = 'none';

/// 선택 가능한 인덱스 탭 (none이 맨 앞).
const List<String> coverTabPalette = ['none', 'colorful', 'pink', 'blue'];

/// 한글 라벨.
const Map<String, String> coverTabLabels = {
  'none': '없음',
  'colorful': '컬러풀',
  'pink': '핑크',
  'blue': '블루',
};

/// 알 수 없는/누락 id는 none으로 정규화한다.
String normalizeCoverTab(String? id) {
  if (id == null || !coverTabPalette.contains(id)) return kDefaultCoverTab;
  return id;
}

/// 한글 라벨(없으면 id 그대로).
String coverTabLabel(String id) => coverTabLabels[id] ?? id;
