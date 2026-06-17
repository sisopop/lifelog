import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/journals/default_journal_provider.dart';

/// Bottom navigation with 5 slots. The center (+) is not a branch —
/// it pushes the write screen for the user's default journal.
class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (_NavSpec(Icons.home_outlined, Icons.home, '홈')),
    (_NavSpec(Icons.article_outlined, Icons.article, '기록')),
    (_NavSpec(Icons.add, Icons.add, '')), // center +
    (_NavSpec(Icons.insights_outlined, Icons.insights, '회고')),
    (_NavSpec(Icons.people_outline, Icons.people, '사람')),
  ];

  // Map visible nav index <-> shell branch index (skip the center +).
  int _branchToNav(int branch) => branch < 2 ? branch : branch + 1;
  int _navToBranch(int nav) => nav < 2 ? nav : nav - 1;

  void _onTap(BuildContext context, WidgetRef ref, int navIndex) {
    if (navIndex == 2) {
      // Quick-write goes to the user's default journal (Settings → 기본 일기장).
      final target = ref.read(defaultJournalProvider);
      context.push(writeRouteForJournal(ref, target));
      return;
    }
    final branch = _navToBranch(navIndex);
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNav = _branchToNav(navigationShell.currentIndex);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_items.length, (i) {
                final spec = _items[i];
                if (i == 2) {
                  return _CenterButton(onTap: () => _onTap(context, ref, i));
                }
                final selected = i == currentNav;
                return Expanded(
                  child: InkWell(
                    onTap: () => _onTap(context, ref, i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? spec.active : spec.inactive,
                          color: selected ? AppColors.primary : AppColors.textHint,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spec.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? AppColors.primary : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.inactive, this.active, this.label);
  final IconData inactive;
  final IconData active;
  final String label;
}
