class AppConfig {
  final String id;
  final String appName;
  final String packageName;
  final String platform;
  final String status; // 'active', 'maintenance', 'inactive'
  final String minVersion;
  final String latestVersion;
  final int minVersionCode;
  final int latestVersionCode;
  final bool forceUpdate;
  final String updateMode; // 'immediate', 'flexible'
  final String updateTitle;
  final String updateDescription;
  final String updateButtonText;
  final String updateUrl;
  final bool isCancelable;
  final List<AppAdConfig> ads;
  final List<AppButtonConfig> buttons;

  AppConfig({
    required this.id,
    required this.appName,
    required this.packageName,
    this.platform = 'android',
    this.status = 'active',
    required this.minVersion,
    required this.latestVersion,
    this.minVersionCode = 1,
    this.latestVersionCode = 1,
    required this.forceUpdate,
    this.updateMode = 'immediate',
    required this.updateTitle,
    required this.updateDescription,
    this.updateButtonText = 'UPDATE NOW',
    required this.updateUrl,
    required this.isCancelable,
    required this.ads,
    required this.buttons,
  });

  bool get isMaintenance => status.toLowerCase() == 'maintenance';
  bool get isInactive => status.toLowerCase() == 'inactive';

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final adsList = (json['app_ads'] as List<dynamic>? ?? [])
        .map((a) => AppAdConfig.fromJson(a as Map<String, dynamic>))
        .toList();

    final buttonsList = (json['app_buttons'] as List<dynamic>? ?? [])
        .map((b) => AppButtonConfig.fromJson(b as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return AppConfig(
      id: json['id']?.toString() ?? '',
      appName: json['app_name']?.toString() ?? 'Calculator',
      packageName:
          json['package_name']?.toString() ?? 'com.dimension.calculator',
      platform: json['platform']?.toString() ?? 'android',
      status: json['status']?.toString() ?? 'active',
      minVersion: json['min_version']?.toString() ?? '1.0.0',
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      minVersionCode: (json['min_version_code'] as num?)?.toInt() ?? 1,
      latestVersionCode: (json['latest_version_code'] as num?)?.toInt() ?? 1,
      forceUpdate: json['force_update'] == true,
      updateMode: json['update_mode']?.toString() ?? 'immediate',
      updateTitle: json['update_title']?.toString() ?? 'Update Required',
      updateDescription: json['update_description']?.toString() ??
          'A newer and faster version is available. Please update now!',
      updateButtonText:
          json['update_button_text']?.toString() ?? 'UPDATE NOW',
      updateUrl: json['update_url']?.toString() ??
          'https://play.google.com/store/apps/details?id=com.dimension.calculator',
      isCancelable: json['is_cancelable'] == true,
      ads: adsList,
      buttons: buttonsList,
    );
  }

  AppAdConfig? getAd(String adType) {
    try {
      return ads.firstWhere((a) => a.adType == adType);
    } catch (_) {
      return null;
    }
  }

  /// Check if the currently installed version is older than minVersion or minVersionCode
  bool isUpdateRequired(String currentVersion, [int? currentVersionCode]) {
    if (currentVersionCode != null && minVersionCode > 0) {
      if (currentVersionCode < minVersionCode) return true;
    }
    return _isVersionOlder(currentVersion, minVersion);
  }

  static bool _isVersionOlder(String current, String target) {
    try {
      final currentParts =
          current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final targetParts =
          target.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final t = i < targetParts.length ? targetParts[i] : 0;
        if (c < t) return true;
        if (c > t) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

class AppAdConfig {
  final String id;
  final String appId;
  final String adType; // 'app_open', 'banner', 'interstitial'
  final bool isEnabled;
  final String provider; // 'admob', 'applovin', 'unity'
  final String primaryAdUnitId;
  final String secondaryAdUnitId;
  final int clickInterval;
  final int refreshRate;
  final int delaySeconds;
  final String position;
  final bool testMode;
  final Map<String, dynamic> extraConfig;
  final String realAdUnitId;
  final String testAdUnitId;
  final String servingMode; // 'production', 'test_only', 'smart'
  final bool enableRealAds;
  final bool enableTestAds;

  AppAdConfig({
    required this.id,
    this.appId = '',
    required this.adType,
    required this.isEnabled,
    this.provider = 'admob',
    required this.primaryAdUnitId,
    required this.secondaryAdUnitId,
    required this.clickInterval,
    required this.refreshRate,
    required this.delaySeconds,
    required this.position,
    required this.testMode,
    this.extraConfig = const {},
    this.realAdUnitId = '',
    this.testAdUnitId = '',
    this.servingMode = 'production',
    this.enableRealAds = true,
    this.enableTestAds = true,
  });

  factory AppAdConfig.fromJson(Map<String, dynamic> json) {
    final extra = json['extra_config'] as Map<String, dynamic>? ?? {};
    final realId = extra['real_ad_unit_id']?.toString().trim() ?? '';
    var testId = extra['test_ad_unit_id']?.toString().trim() ?? '';
    final adType = json['ad_type']?.toString().trim() ?? '';

    // Sanitize official Google Mobile Ads test IDs
    if (adType == 'app_open') {
      if (testId.isEmpty || testId.contains('3419832817')) {
        testId = 'ca-app-pub-3940256099942544/9257395921';
      }
    } else if (adType == 'banner') {
      if (testId.isEmpty) {
        testId = 'ca-app-pub-3940256099942544/6300978111';
      }
    }

    final sMode = extra['serving_mode']?.toString().trim().toLowerCase() ??
        'production';
    final enableReal = extra['enable_real_ads'] != false;
    final enableTest = extra['enable_test_ads'] != false;

    // Dynamic banner position strictly remote-controlled by Supabase ('top' or 'bottom')
    final rawPos = (json['position'] ?? extra['position'])
            ?.toString()
            .trim()
            .toLowerCase() ??
        'bottom';
    final pos = (rawPos == 'top') ? 'top' : 'bottom';

    return AppAdConfig(
      id: json['id']?.toString() ?? '',
      appId: json['app_id']?.toString() ?? '',
      adType: adType,
      isEnabled: json['is_enabled'] == true,
      provider: json['provider']?.toString() ?? 'admob',
      primaryAdUnitId: json['primary_ad_unit_id']?.toString().trim() ?? '',
      secondaryAdUnitId: json['secondary_ad_unit_id']?.toString().trim() ?? '',
      clickInterval: (json['click_interval'] as num?)?.toInt() ?? 5,
      refreshRate: (json['refresh_rate'] as num?)?.toInt() ?? 30,
      delaySeconds: (json['delay_seconds'] as num?)?.toInt() ?? 0,
      position: pos,
      testMode: json['test_mode'] == true,
      extraConfig: extra,
      realAdUnitId: realId,
      testAdUnitId: testId,
      servingMode: sMode,
      enableRealAds: enableReal,
      enableTestAds: enableTest,
    );
  }

  /// Resolve dynamic ad unit ID strictly according to Supabase extra_config & device status
  String resolveAdUnitId({bool isDeviceTest = false}) {
    final bool useTest = isDeviceTest || testMode || servingMode == 'test_only';

    // 1. If device is tester device or serving_mode == 'test_only'
    if (useTest) {
      if (testAdUnitId.isNotEmpty) return testAdUnitId;
      if (primaryAdUnitId.isNotEmpty) return primaryAdUnitId;
      if (secondaryAdUnitId.isNotEmpty) return secondaryAdUnitId;
    }

    // 2. Production mode
    if (servingMode == 'production') {
      if (realAdUnitId.isNotEmpty) return realAdUnitId;
      if (primaryAdUnitId.isNotEmpty) return primaryAdUnitId;
      // Safe fallback to testAdUnitId if real ID is not yet provided in admin panel
      if (testAdUnitId.isNotEmpty) return testAdUnitId;
      if (secondaryAdUnitId.isNotEmpty) return secondaryAdUnitId;
    }

    // 3. Smart mode: serve real if present & not test device, else test ID
    if (servingMode == 'smart') {
      if (!isDeviceTest && realAdUnitId.isNotEmpty) return realAdUnitId;
      if (testAdUnitId.isNotEmpty) return testAdUnitId;
      if (primaryAdUnitId.isNotEmpty) return primaryAdUnitId;
    }

    // 4. Default priority resolution
    if (primaryAdUnitId.isNotEmpty) return primaryAdUnitId;
    if (realAdUnitId.isNotEmpty) return realAdUnitId;
    if (testAdUnitId.isNotEmpty) return testAdUnitId;
    if (secondaryAdUnitId.isNotEmpty) return secondaryAdUnitId;

    return '';
  }
}

class AppButtonConfig {
  final String id;
  final String appId;
  final String buttonKey;
  final String title;
  final String subtitle;
  final String icon; // Emoji (🛡️, 📤, ⭐, 🗑️, 🎨, 💬) or keyword (shield, share...)
  final String actionType; // 'policy', 'share', 'rate', 'clear_history', 'theme', 'feedback', 'url'
  final String actionUrl;
  final bool isVisible;
  final int sortOrder;
  final String badgeText;

  AppButtonConfig({
    required this.id,
    this.appId = '',
    required this.buttonKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionType,
    required this.actionUrl,
    required this.isVisible,
    required this.sortOrder,
    required this.badgeText,
  });

  factory AppButtonConfig.fromJson(Map<String, dynamic> json) {
    return AppButtonConfig(
      id: json['id']?.toString() ?? '',
      appId: json['app_id']?.toString() ?? '',
      buttonKey: json['button_key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'link',
      actionType: json['action_type']?.toString() ?? 'url',
      actionUrl: json['action_url']?.toString() ?? '',
      isVisible: json['is_visible'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      badgeText: json['badge_text']?.toString() ?? '',
    );
  }
}

class DeviceStatus {
  final String id;
  final String appId;
  final String deviceId;
  final String deviceModel;
  final String manufacturer;
  final String osVersion;
  final String appVersion;
  final bool isBanned;
  final String banReason;
  final bool isTestDevice;

  DeviceStatus({
    this.id = '',
    this.appId = '',
    required this.deviceId,
    this.deviceModel = '',
    this.manufacturer = '',
    this.osVersion = '',
    this.appVersion = '',
    required this.isBanned,
    required this.banReason,
    required this.isTestDevice,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      id: json['id']?.toString() ?? '',
      appId: json['app_id']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      deviceModel: json['device_model']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      osVersion: json['os_version']?.toString() ?? '',
      appVersion: json['app_version']?.toString() ?? '',
      isBanned: json['is_banned'] == true,
      banReason: json['ban_reason']?.toString() ?? '',
      isTestDevice: json['is_test_device'] == true,
    );
  }
}
