// 글 + 사진 "블록 흐름"(인라인 사진) 모델.
//
// 자유 캔버스(page_canvas: 페이지 위에 떠 있는 스티커·사진을 아무 데나 배치)와
// 달리, 여기서는 사진이 본문 *글 흐름 안*에 **전체 폭 블록**으로 끼어 글을 위/아래로
// 나눈다(글 폭은 좁아지지 않는다). 본문(DiaryEntry.content)은 지금처럼 **순수
// 텍스트 그대로** 두고(검색·통계·백업 무손상), 사진의 "끼움 위치"만 따로 저장해
// 렌더할 때 합친다. 즉 글 조각 수 = (끼운 사진 수 + 1) 이하이지, 문단마다 블록이
// 되는 게 아니다.

/// 본문 흐름 안에 끼우는 사진 한 장.
/// [path]는 이미지 경로(데이터 URL·http·file 등), [afterParagraph]는 이 사진
/// *앞에 오는 문단 수*(0=맨 위, 전체 문단 수=맨 아래)를 뜻한다.
class InlinePhoto {
  const InlinePhoto({required this.path, required this.afterParagraph});

  final String path;
  final int afterParagraph;
}

/// 흐름 블록의 종류.
enum FlowBlockKind { text, photo }

/// 렌더 순서대로 나열되는 한 블록: 글(text) 또는 사진(photo).
/// text면 [text]에 (문단들을 이어붙인) 글, photo면 [photoPath]에 이미지 경로.
class FlowBlock {
  const FlowBlock.text(String this.text)
      : kind = FlowBlockKind.text,
        photoPath = null;

  const FlowBlock.photo(String this.photoPath)
      : kind = FlowBlockKind.photo,
        text = null;

  final FlowBlockKind kind;
  final String? text;
  final String? photoPath;
}

/// 문단(빈 줄 경계)으로 나눈 뒤 앞뒤 공백을 다듬은 비어있지 않은 문단 목록.
List<String> _splitParagraphs(String text) => text
    .split(RegExp(r'\n[ \t]*\n'))
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty)
    .toList();

int _clampPos(int pos, int max) => pos < 0 ? 0 : (pos > max ? max : pos);

/// 본문 텍스트와 끼움 사진들을 렌더 순서 블록 목록으로 합친다.
///
/// 문단을 기준으로 각 사진을 [InlinePhoto.afterParagraph] 위치(0..문단수로 가둠)에
/// 끼우고, 사진 사이의 문단들은 하나의 글 블록으로 이어붙인다. 같은 위치의 사진은
/// 넣은 순서대로 연달아 놓인다. [path]가 빈 사진은 건너뛴다. 순수 함수(부수효과·
/// 예외 없음). 본문이 비어 있고 사진도 없으면 빈 목록을 돌려준다.
List<FlowBlock> buildContentFlow(String content, List<InlinePhoto> photos) {
  final paragraphs = _splitParagraphs(content);
  final max = paragraphs.length;
  // 빈 경로 사진은 먼저 제외한다(끼움도 텍스트 분할도 일으키지 않도록).
  final sorted = photos.where((p) => p.path.trim().isNotEmpty).toList()
    ..sort((a, b) =>
        _clampPos(a.afterParagraph, max).compareTo(_clampPos(b.afterParagraph, max)));

  final blocks = <FlowBlock>[];
  var idx = 0; // 다음에 낼 문단 인덱스
  for (final p in sorted) {
    final pos = _clampPos(p.afterParagraph, max);
    if (pos > idx) {
      blocks.add(FlowBlock.text(paragraphs.sublist(idx, pos).join('\n\n')));
      idx = pos;
    }
    blocks.add(FlowBlock.photo(p.path));
  }
  if (idx < max) {
    blocks.add(FlowBlock.text(paragraphs.sublist(idx).join('\n\n')));
  }
  return blocks;
}
