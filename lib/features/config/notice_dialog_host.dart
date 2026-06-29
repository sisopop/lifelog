import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../auth/session.dart';
import 'remote_config.dart';
import 'remote_config_provider.dart';

const _kSeenKey = 'seenDialogNotices';

/// Invisible host that pops the next live dialog-type notice from
/// [remoteConfigProvider] exactly once. Dismissed ids are stored in
/// SharedPreferences so the same announcement never nags the user again.
/// Renders nothing — drop it into the home tree like a banner.
class NoticeDialogHost extends ConsumerStatefulWidget {
  const NoticeDialogHost({super.key});

  @override
  ConsumerState<NoticeDialogHost> createState() => _NoticeDialogHostState();
}

class _NoticeDialogHostState extends ConsumerState<NoticeDialogHost> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    // Config arrives async (Firestore stream); act on the first frame that
    // carries an unseen dialog notice, then never again this session.
    final config = ref.watch(remoteConfigProvider);
    if (!_handled) {
      final prefs = ref.read(sharedPrefsProvider);
      final seen = prefs.getStringList(_kSeenKey)?.toSet() ?? <String>{};
      final notice = config.nextDialogNotice(DateTime.now(), seen);
      if (notice != null) {
        _handled = true;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _show(prefs, seen, notice),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _show(
      SharedPreferences prefs, Set<String> seen, AppNotice notice) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: AppColors.primaryDark, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(notice.title)),
          ],
        ),
        content:
            notice.body.trim().isEmpty ? null : Text(notice.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    await prefs.setStringList(_kSeenKey, {...seen, notice.id}.toList());
  }
}
