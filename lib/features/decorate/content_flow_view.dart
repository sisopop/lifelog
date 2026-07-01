import 'package:flutter/material.dart';

import '../../shared/widgets/photo.dart';
import 'content_flow.dart';

/// [content]와 [photos]를 "글 흐름"으로 렌더하는 읽기 전용 위젯.
///
/// 글은 전체 폭 [Text], 사진은 전체 폭 블록으로 그려 글을 위/아래로 나눈다
/// (글 폭은 좁아지지 않는다). [photoBuilder]로 사진 렌더를 갈아끼울 수 있어,
/// 데모/테스트에서 실제 이미지 없이 자리표시자를 넣을 수 있다(기본은 [PhotoView]).
class ContentFlowView extends StatelessWidget {
  const ContentFlowView({
    super.key,
    required this.content,
    this.photos = const [],
    this.textStyle,
    this.photoBuilder,
    this.spacing = 12,
  });

  final String content;
  final List<InlinePhoto> photos;
  final TextStyle? textStyle;
  final Widget Function(String path)? photoBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final blocks = buildContentFlow(content, photos);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0) children.add(SizedBox(height: spacing));
      final b = blocks[i];
      if (b.kind == FlowBlockKind.text) {
        children.add(Text(b.text!, style: textStyle));
      } else {
        children.add(
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (photoBuilder ?? _defaultPhoto)(b.photoPath!),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _defaultPhoto(String path) =>
      PhotoView(path, height: 200, iconSize: 48);
}
