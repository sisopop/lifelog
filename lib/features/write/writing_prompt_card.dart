import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Inspiration card shown on the write screen while the body is empty.
/// Tapping the card uses the prompt as a starting line; the refresh icon
/// cycles to another prompt.
class WritingPromptCard extends StatelessWidget {
  const WritingPromptCard({
    super.key,
    required this.prompt,
    required this.onUse,
    required this.onRefresh,
  });

  final String prompt;
  final VoidCallback onUse;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onUse,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  const Text('✍️ ', style: TextStyle(fontSize: 15)),
                  Expanded(
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: '다른 글감',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh,
                size: 20, color: AppColors.primaryDark),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
