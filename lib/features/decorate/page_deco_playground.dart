import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'content_flow_demo.dart';
import 'page_canvas.dart';
import 'page_deco_editor.dart';

/// 기록 페이지 꾸미기 캔버스 에디터(호스트 화면).
///
/// 실제 편집 캔버스·툴바·제스처는 재사용 위젯 [PageDecoEditor]로 추출했고, 이
/// 화면은 그것을 감싸는 얇은 껍데기(AppBar 크롬 + 완료/되돌리기/지우기 버튼)만
/// 담당한다. 두 가지 모드로 쓰인다:
///  - **실험용**(기본): [initial]/[onDone] 없이 열면 저장 없이 자유롭게 만져보는
///    프로토타입(설정 → "페이지 꾸미기(실험)").
///  - **실기록 편집**: [initial]에 기존 캔버스를 주고 [onDone]를 넘기면, 상단
///    "완료" 버튼이 현재 캔버스를 콜백으로 돌려준다(빈 캔버스면 null → 꾸미기 해제).
class PageDecoPlayground extends StatefulWidget {
  const PageDecoPlayground({
    super.key,
    this.initial,
    this.onDone,
    this.title = '페이지 꾸미기 (실험)',
    this.titleText = '',
    this.contentText = '',
  });

  /// 편집을 시작할 캔버스. null이면 빈 캔버스에서 시작.
  final PageCanvas? initial;

  /// 지금까지 쓴 일기 제목. 종이 맨 위에 굵게 깔아, 실제 일기 모습 그대로를
  /// 배경으로 보며 그 위에 꾸미게 한다(빈 문자열이면 제목 줄을 생략).
  final String titleText;

  /// 지금까지 쓴 본문. 종이 위에 바탕 글로 깔아, 스티커를 "쓴 글 주변"에 놓게 한다
  /// (제목·본문 모두 비었으면 종이만 꾸미는 실험 모드처럼 안내 문구를 보여준다).
  final String contentText;

  /// 실기록 편집 모드: "완료" 버튼을 누르면 현재 캔버스를 돌려준다. 캔버스가
  /// 비어 있으면(무늬 plain·레이어 없음) null을 돌려 "꾸미기 없음"을 뜻한다.
  final ValueChanged<PageCanvas?>? onDone;

  final String title;

  @override
  State<PageDecoPlayground> createState() => _PageDecoPlaygroundState();
}

class _PageDecoPlaygroundState extends State<PageDecoPlayground> {
  late final PageDecoEditorController _ctrl =
      PageDecoEditorController(initial: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.onDone == null)
            IconButton(
              tooltip: '글 흐름 미리보기',
              icon: const Icon(Icons.view_agenda_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContentFlowDemo()),
              ),
            ),
          // 레이어 유무에 따라 되돌리기/모두 지우기/완료 버튼을 갱신한다.
          ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_ctrl.hasLayers)
                    IconButton(
                      tooltip: '실행 취소',
                      icon: const Icon(Icons.undo),
                      onPressed: _ctrl.undoLast,
                    ),
                  if (_ctrl.hasLayers)
                    IconButton(
                      tooltip: '모두 지우기',
                      icon: const Icon(Icons.delete_sweep_outlined),
                      onPressed: _ctrl.clearLayers,
                    ),
                  if (widget.onDone != null)
                    TextButton(
                      onPressed: () =>
                          widget.onDone!(_ctrl.isBlank ? null : _ctrl.canvas),
                      child: const Text('완료'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: PageDecoEditor(
        controller: _ctrl,
        titleText: widget.titleText,
        contentText: widget.contentText,
      ),
    );
  }
}
