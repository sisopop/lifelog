import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'remote_config.dart';

/// App-wide remote config (feature flags + notices) the rest of the app reads.
///
/// SKELETON: returns a local dummy value. When the Firebase backend lands,
/// swap ONLY this provider's body for a real fetch (Firestore `config/app` +
/// `notices`, with an offline cache fallback). Every reader watches
/// [RemoteConfig] and stays unchanged.
final remoteConfigProvider = Provider<RemoteConfig>((ref) {
  return dummyRemoteConfig();
});
