import 'package:flutter_test/flutter_test.dart';
import 'package:premium_calculator/models/app_config.dart';

void main() {
  group('AppConfig & Version Checking Tests', () {
    test('Correctly parses joined JSON from Supabase REST GET call', () {
      final json = {
        'id': '5829f424-0129-498c-8e76-3b93fbf63aed',
        'app_name': 'Calculator',
        'package_name': 'com.dimension.calculator',
        'min_version': '1.0.0',
        'latest_version': '1.2.0',
        'force_update': false,
        'update_title': 'New Update Available',
        'update_description': 'Check out new features',
        'update_url': 'https://play.google.com/store/apps/details?id=com.dimension.calculator',
        'is_cancelable': true,
        'app_ads': [
          {
            'id': 'ad1',
            'ad_type': 'app_open',
            'is_enabled': true,
            'primary_ad_unit_id': 'ca-app-pub-test/1',
            'secondary_ad_unit_id': '',
            'click_interval': 5,
            'refresh_rate': 30,
            'delay_seconds': 0,
            'position': 'top',
            'test_mode': true,
          },
          {
            'id': 'ad2',
            'ad_type': 'banner',
            'is_enabled': true,
            'primary_ad_unit_id': 'ca-app-pub-test/2',
            'secondary_ad_unit_id': '',
            'click_interval': 5,
            'refresh_rate': 30,
            'delay_seconds': 0,
            'position': 'bottom',
            'test_mode': true,
          },
        ],
        'app_buttons': [
          {
            'id': 'b1',
            'button_key': 'privacy_policy',
            'title': 'Privacy Policy',
            'subtitle': '',
            'icon': 'shield',
            'action_type': 'policy',
            'action_url': '',
            'is_visible': true,
            'sort_order': 1,
            'badge_text': '',
          },
          {
            'id': 'b2',
            'button_key': 'share_app',
            'title': 'Share App',
            'subtitle': '',
            'icon': 'share',
            'action_type': 'share',
            'action_url': '',
            'is_visible': false,
            'sort_order': 2,
            'badge_text': '',
          },
        ],
      };

      final config = AppConfig.fromJson(json);

      expect(config.appName, 'Calculator');
      expect(config.packageName, 'com.dimension.calculator');
      expect(config.ads.length, 2);
      expect(config.buttons.length, 2);
      expect(config.getAd('banner')?.isEnabled, true);
      expect(config.getAd('interstitial'), isNull);
    });

    test('Semantic version comparison logic', () {
      final config = AppConfig(
        id: '1',
        appName: 'Calculator',
        packageName: 'com.dimension.calculator',
        minVersion: '1.2.0',
        latestVersion: '1.3.0',
        forceUpdate: true,
        updateTitle: 'Update',
        updateDescription: 'Desc',
        updateUrl: 'http://example.com',
        isCancelable: false,
        ads: [],
        buttons: [],
      );

      // Current 1.0.0 is older than minVersion 1.2.0 -> update required
      expect(config.isUpdateRequired('1.0.0'), true);
      expect(config.isUpdateRequired('1.1.9'), true);

      // Current 1.2.0 is equal to minVersion -> update NOT required
      expect(config.isUpdateRequired('1.2.0'), false);

      // Current 2.0.0 is newer than minVersion -> update NOT required
      expect(config.isUpdateRequired('2.0.0'), false);
    });

    test('DeviceStatus JSON parsing', () {
      final json = {
        'device_id': 'dev_test_123',
        'is_banned': true,
        'ban_reason': 'Violation of Terms',
        'is_test_device': true,
      };

      final status = DeviceStatus.fromJson(json);
      expect(status.deviceId, 'dev_test_123');
      expect(status.isBanned, true);
      expect(status.banReason, 'Violation of Terms');
      expect(status.isTestDevice, true);
    });

    test('AppAdConfig correctly supplies dynamic unit IDs without hardcoding', () {
      final adConfig = AppAdConfig(
        id: 'ad_1',
        adType: 'app_open',
        isEnabled: true,
        primaryAdUnitId: 'ca-app-pub-custom-12345/99999',
        secondaryAdUnitId: 'ca-app-pub-custom-fallback/88888',
        clickInterval: 3,
        refreshRate: 30,
        delaySeconds: 0,
        position: 'splash',
        testMode: false,
      );

      expect(adConfig.primaryAdUnitId, 'ca-app-pub-custom-12345/99999');
      expect(adConfig.secondaryAdUnitId, 'ca-app-pub-custom-fallback/88888');
      expect(adConfig.isEnabled, true);
    });

    test('AppAdConfig resolveAdUnitId with extra_config and serving_mode', () {
      final json = {
        'id': 'ad_2',
        'ad_type': 'app_open',
        'is_enabled': true,
        'primary_ad_unit_id': '',
        'secondary_ad_unit_id': '',
        'extra_config': {
          'serving_mode': 'production',
          'real_ad_unit_id': 'ca-app-pub-real/11111',
          'test_ad_unit_id': 'ca-app-pub-test/22222',
        },
        'test_mode': false,
      };

      final adConfig = AppAdConfig.fromJson(json);
      // When in production mode on a regular device:
      expect(adConfig.resolveAdUnitId(isDeviceTest: false), 'ca-app-pub-real/11111');
      // When flagged as a tester device in app_devices table:
      expect(adConfig.resolveAdUnitId(isDeviceTest: true), 'ca-app-pub-test/22222');
    });

    test('AppConfig parses maintenance and version codes', () {
      final config = AppConfig(
        id: 'app_1',
        appName: 'Calculator',
        packageName: 'com.dimension.calculator',
        status: 'maintenance',
        minVersion: '1.0.0',
        latestVersion: '1.2.0',
        minVersionCode: 2,
        latestVersionCode: 3,
        forceUpdate: false,
        updateTitle: 'Notice',
        updateDescription: 'Maintenance ongoing',
        updateUrl: '',
        isCancelable: true,
        ads: [],
        buttons: [],
      );

      expect(config.isMaintenance, true);
      expect(config.isUpdateRequired('1.0.0', 1), true);
      expect(config.isUpdateRequired('1.0.0', 2), false);
    });

    test('AppAdConfig correctly parses dynamic banner position from Supabase', () {
      final jsonTop = {
        'id': 'ad_banner_top',
        'ad_type': 'banner',
        'is_enabled': true,
        'position': 'top',
      };
      final adTop = AppAdConfig.fromJson(jsonTop);
      expect(adTop.position, 'top');

      final jsonBottom = {
        'id': 'ad_banner_bottom',
        'ad_type': 'banner',
        'is_enabled': true,
        'position': 'bottom',
      };
      final adBottom = AppAdConfig.fromJson(jsonBottom);
      expect(adBottom.position, 'bottom');
    });
  });
}
