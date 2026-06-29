import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'remote_config.dart';

/// Live feature flags from Firestore `config/app`. Emits the `features` map
/// (admin-controlled). Errors/offline-without-cache surface as AsyncError, so
/// [remoteConfigProvider] can fall back to the dummy without a regression.
final _featuresProvider = StreamProvider<Map<String, bool>>((ref) {
  final doc = FirebaseFirestore.instance.collection('config').doc('app');
  return doc.snapshots().map((snap) {
    final features = <String, bool>{};
    final raw = snap.data()?['features'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is bool) features[k.toString()] = v;
      });
    }
    return features;
  });
});

/// Live admin-authored notices from the Firestore `notices` collection.
final _noticesProvider = StreamProvider<List<AppNotice>>((ref) {
  final col = FirebaseFirestore.instance.collection('notices');
  return col.snapshots().map(
        (snap) => snap.docs.map(_noticeFromDoc).toList(),
      );
});

/// Pure-ish: map one Firestore notice document to an [AppNotice].
AppNotice _noticeFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data();
  return AppNotice(
    id: d.id,
    title: (m['title'] ?? '').toString(),
    body: (m['body'] ?? '').toString(),
    type: noticeTypeFromName(m['type'] as String?),
    active: m['active'] as bool? ?? true,
    startAt: _toDate(m['startAt']),
    endAt: _toDate(m['endAt']),
  );
}

/// Lenient: Firestore [Timestamp], epoch ms, ISO string, or DateTime → DateTime.
DateTime? _toDate(Object? v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// App-wide remote config (feature flags + notices) the rest of the app reads.
///
/// Backed by Firestore (`config/app` + `notices`). Until the first snapshot
/// arrives — or when offline with no cache — it degrades to [dummyRemoteConfig]
/// so a missing/unreachable backend never hides the user's surfaces. Every
/// reader watches a plain [RemoteConfig] and stays unchanged.
final remoteConfigProvider = Provider<RemoteConfig>((ref) {
  final features = ref.watch(_featuresProvider).asData?.value;
  final notices = ref.watch(_noticesProvider).asData?.value;
  if (features == null && notices == null) return dummyRemoteConfig();
  return RemoteConfig(
    features: features ?? const {},
    notices: notices ?? const [],
  );
});
