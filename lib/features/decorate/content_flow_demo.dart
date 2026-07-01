import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'content_flow.dart';
import 'content_flow_view.dart';

/// "글 + 사진 블록 흐름" 미리보기 데모(실험).
///
/// 실기록/실이미지 없이 [ContentFlowView]의 배치 규칙만 눈으로 확인하는 화면.
/// 사진은 실제 이미지 대신 자리표시자 박스로 그려, 글이 사진을 기준으로 위/아래로
/// 나뉘는 흐름을 보여준다.
class ContentFlowDemo extends StatelessWidget {
  const ContentFlowDemo({super.key});

  static const _content =
      '오늘은 아침 일찍 바다에 갔다.\n파도 소리가 좋았다.\n\n'
      '점심에는 근처 식당에서 회를 먹었다.\n생각보다 양이 많았다.\n\n'
      '저녁에는 노을을 보며 산책했다.\n하루가 알차게 지나갔다.';

  @override
  Widget build(BuildContext context) {
    // 첫 문단(2줄) 뒤에 사진 한 장을 끼운다 → 글이 위/아래로 나뉜다.
    const photos = [InlinePhoto(path: 'demo', afterParagraph: 1)];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('글 흐름 미리보기 (실험)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ContentFlowView(
            content: _content,
            photos: photos,
            textStyle: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
            photoBuilder: (_) => _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 160,
        color: AppColors.primarySoft,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 40, color: AppColors.primary),
            SizedBox(height: 6),
            Text('사진 블록', style: TextStyle(color: AppColors.primary)),
          ],
        ),
      );
}
