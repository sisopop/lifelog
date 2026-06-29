import 'package:flutter/foundation.dart';

/// How an admin-authored notice is surfaced to the user.
enum NoticeType { banner, dialog }

/// Pure: resolve a stored name to a [NoticeType], defaulting to [banner].
NoticeType noticeTypeFromName(String? name) {
  for (final t in NoticeType.values) {
    if (t.name == name) return t;
  }
  return NoticeType.banner;
}

/// A single announcement authored in the (future) admin console. Shape mirrors
/// the planned Firestore `notices/{id}` document so [fromJson] works unchanged
/// once a real backend is wired in.
@immutable
class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    this.body = '',
    this.type = NoticeType.banner,
    this.active = true,
    this.startAt,
    this.endAt,
  });

  final String id;
  final String title;
  final String body;
  final NoticeType type;
  final bool active;

  /// Optional visibility window; null means "no bound".
  final DateTime? startAt;
  final DateTime? endAt;

  /// Pure: is this notice live at [now]? Must be active and within
  /// [startAt, endAt] (inclusive) when those bounds are set.
  bool isLiveAt(DateTime now) {
    if (!active) return false;
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }

  factory AppNotice.fromJson(Map<String, dynamic> json) => AppNotice(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        type: noticeTypeFromName(json['type'] as String?),
        active: json['active'] as bool? ?? true,
        startAt: _parseDate(json['startAt']),
        endAt: _parseDate(json['endAt']),
      );
}

/// Pure: lenient date parsing for backend payloads (ISO string, epoch ms, or an
/// already-parsed DateTime). Returns null for anything unrecognized.
DateTime? _parseDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// App-wide config the admin console controls and the app reads at launch.
/// Mirrors the planned Firestore `config/app` document plus the `notices`
/// collection, folded into one immutable value the UI can watch.
@immutable
class RemoteConfig {
  const RemoteConfig({
    this.features = const {},
    this.notices = const [],
  });

  /// Feature flags, e.g. {'ads': false, 'limitedSales': true}.
  final Map<String, bool> features;
  final List<AppNotice> notices;

  /// Pure: is feature [key] on? Falls back to [orElse] when the flag is unset
  /// (so a missing/offline config degrades to a safe default per call site).
  bool isFeatureEnabled(String key, {bool orElse = false}) =>
      features[key] ?? orElse;

  /// Pure: notices live at [now], in declared order. When [bannersOnly] is set,
  /// dialog-type notices are excluded (the home banner wants banners only).
  List<AppNotice> liveNotices(DateTime now, {bool bannersOnly = false}) =>
      notices
          .where((n) => n.isLiveAt(now))
          .where((n) => !bannersOnly || n.type == NoticeType.banner)
          .toList();

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    final features = <String, bool>{};
    final rawFeatures = json['features'];
    if (rawFeatures is Map) {
      rawFeatures.forEach((k, v) {
        if (v is bool) features[k.toString()] = v;
      });
    }
    final notices = <AppNotice>[];
    final rawNotices = json['notices'];
    if (rawNotices is List) {
      for (final n in rawNotices) {
        if (n is Map) {
          notices.add(AppNotice.fromJson(Map<String, dynamic>.from(n)));
        }
      }
    }
    return RemoteConfig(features: features, notices: notices);
  }
}

/// SKELETON dummy config standing in for the backend until Firebase is wired
/// in. Replace [remoteConfigProvider]'s body (not this) with a real fetch then.
RemoteConfig dummyRemoteConfig() => RemoteConfig(
      features: const {
        'ads': false,
        'limitedSales': true,
        'skinShop': false,
      },
      notices: [
        const AppNotice(
          id: 'skeleton-welcome',
          title: '리모트 설정이 연결됐어요',
          body: '앞으로 공지와 기능은 관리자 페이지에서 제어됩니다.',
        ),
      ],
    );
