import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 꾸미기 탭 하단의 **드래그로 높이가 조절되는** 컨트롤 시트. 맨 위 그립 손잡이를
/// 위/아래로 끌어 시트를 키우거나 접는다(접으면 위 캔버스가 넓게 드러난다). 안에는
/// 하위 6탭(속지/…/텍스트)과 각 탭 컨트롤이 [child]로 들어온다.
class DecorSheet extends StatefulWidget {
  const DecorSheet({
    super.key,
    required this.minHeight,
    required this.maxHeight,
    required this.initialHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final double initialHeight;
  final Widget child;

  @override
  State<DecorSheet> createState() => _DecorSheetState();
}

class _DecorSheetState extends State<DecorSheet> {
  late double _height = widget.initialHeight;

  @override
  Widget build(BuildContext context) {
    final h = _height.clamp(widget.minHeight, widget.maxHeight).toDouble();
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 그립 손잡이: 위/아래 드래그로 시트 높이를 조절한다(위=크게, 아래=접기).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => setState(() {
              _height = (_height - d.delta.dy)
                  .clamp(widget.minHeight, widget.maxHeight)
                  .toDouble();
            }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
