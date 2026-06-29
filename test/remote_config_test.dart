import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/features/config/remote_config.dart';

void main() {
  group('RemoteConfig.fromJson', () {
    test('parses feature flags and notices from a backend-shaped map', () {
      final config = RemoteConfig.fromJson({
        'features': {'ads': true, 'skinShop': false, 'bogus': 'nope'},
        'notices': [
          {'id': 'n1', 'title': '점검 안내', 'body': '오늘 밤', 'type': 'dialog'},
          {'id': 'n2', 'title': '이벤트'},
        ],
      });
      // Only bool flags are kept; the string 'bogus' is dropped.
      expect(config.isFeatureEnabled('ads'), true);
      expect(config.isFeatureEnabled('skinShop'), false);
      expect(config.isFeatureEnabled('bogus'), false);
      expect(config.notices.length, 2);
      expect(config.notices.first.type, NoticeType.dialog);
      expect(config.notices[1].type, NoticeType.banner); // default
    });

    test('empty/garbage json yields safe empty config', () {
      final empty = RemoteConfig.fromJson(const {});
      expect(empty.features, isEmpty);
      expect(empty.notices, isEmpty);
      final garbage = RemoteConfig.fromJson({'features': 7, 'notices': 'x'});
      expect(garbage.features, isEmpty);
      expect(garbage.notices, isEmpty);
    });
  });

  group('isFeatureEnabled', () {
    test('returns the flag value, else the orElse fallback', () {
      const config = RemoteConfig(features: {'ads': true});
      expect(config.isFeatureEnabled('ads'), true);
      expect(config.isFeatureEnabled('missing'), false);
      expect(config.isFeatureEnabled('missing', orElse: true), true);
    });
  });

  group('AppNotice.isLiveAt', () {
    final now = DateTime(2026, 6, 29, 12);

    test('active with no window is always live', () {
      expect(const AppNotice(id: 'a', title: 't').isLiveAt(now), true);
    });

    test('inactive is never live', () {
      expect(
          const AppNotice(id: 'a', title: 't', active: false).isLiveAt(now),
          false);
    });

    test('respects start and end bounds', () {
      final before = AppNotice(
          id: 'a', title: 't', startAt: DateTime(2026, 6, 30));
      final after =
          AppNotice(id: 'a', title: 't', endAt: DateTime(2026, 6, 28));
      final within = AppNotice(
          id: 'a',
          title: 't',
          startAt: DateTime(2026, 6, 1),
          endAt: DateTime(2026, 7, 1));
      expect(before.isLiveAt(now), false);
      expect(after.isLiveAt(now), false);
      expect(within.isLiveAt(now), true);
    });
  });

  group('liveNotices', () {
    final now = DateTime(2026, 6, 29, 12);

    test('keeps only live notices, banners-only when asked', () {
      final config = RemoteConfig(notices: [
        const AppNotice(id: 'a', title: 'banner-live'),
        const AppNotice(id: 'b', title: 'dialog-live', type: NoticeType.dialog),
        const AppNotice(id: 'c', title: 'inactive', active: false),
        AppNotice(id: 'd', title: 'expired', endAt: DateTime(2026, 6, 1)),
      ]);
      expect(config.liveNotices(now).map((n) => n.id), ['a', 'b']);
      expect(
          config.liveNotices(now, bannersOnly: true).map((n) => n.id), ['a']);
    });
  });

  group('dummyRemoteConfig', () {
    test('exposes a live welcome banner for the skeleton', () {
      final config = dummyRemoteConfig();
      final banners = config.liveNotices(DateTime(2026, 6, 29), bannersOnly: true);
      expect(banners, isNotEmpty);
      expect(config.isFeatureEnabled('ads'), false);
    });
  });
}
