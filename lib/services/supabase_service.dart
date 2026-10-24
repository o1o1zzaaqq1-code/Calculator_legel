import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_config.dart';
import 'admin_panel_service.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  // Supabase Configuration from Blueprint
  static const String supabaseUrl = AdminPanelService.supabaseUrl;
  static const String supabaseAnonKey = AdminPanelService.anonKey;
  static const String packageName = AdminPanelService.packageName;
  static const String appVersion = '1.0.0';

  static const String _cachedConfigKey = 'cached_remote_app_config';

  bool _isInitialized = false;
  String _deviceId = '';
  AppConfig? _appConfig;
  final ValueNotifier<AppConfig?> configNotifier = ValueNotifier<AppConfig?>(null);
  DeviceStatus? _deviceStatus;
  bool get isInitialized => _isInitialized;
  String get deviceId => _deviceId;
  AppConfig? get appConfig => _appConfig;
  DeviceStatus? get deviceStatus => _deviceStatus;
  bool get isBanned => _deviceStatus?.isBanned ?? false;
  String get banReason => _deviceStatus?.banReason ?? '';
  bool get isTestDevice => _deviceStatus?.isTestDevice ?? false;

  /// Visible menu buttons sorted by sort_order
  List<AppButtonConfig> get visibleButtons {
    if (_appConfig == null) return [];
    return _appConfig!.buttons.where((b) => b.isVisible).toList();
  }

  /// Optional remote config string lookup
  String getRemoteConfig(String key) {
    if (key == 'share_text') {
      final shareBtn = _appConfig?.buttons.firstWhere(
        (b) => b.actionType == 'share' || b.buttonKey == 'share_app',
        orElse: () => AppButtonConfig(
          id: '',
          buttonKey: '',
          title: '',
          subtitle: '',
          icon: '',
          actionType: '',
          actionUrl: '',
          isVisible: true,
          sortOrder: 0,
          badgeText: '',
        ),
      );
      if (shareBtn != null && shareBtn.actionUrl.isNotEmpty) {
        return shareBtn.actionUrl;
      }
    }
    return '';
  }

  SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// 1. Initialize Supabase Client and fast-load cached config
  Future<void> initialize() async {
    // Load cached config immediately from local storage for 0ms startup
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedConfigKey);
      if (cached != null && cached.isNotEmpty) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        _appConfig = AppConfig.fromJson(data);
        configNotifier.value = _appConfig;
        print('CRITICAL_CACHE_LOADED: app_ads=${_appConfig?.ads.map((a) => "${a.adType}:${a.position}:${a.isEnabled}").toList()}');
        debugPrint('[SupabaseService] Fast-loaded cached config from disk');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Cache load note: $e');
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Connected to Supabase ($supabaseUrl)');
    } catch (e) {
      debugPrint('[SupabaseService] Initialization note: $e');
    }
  }

  /// 2. Fetch Complete App Configuration in 1 Single GET Call
  Future<AppConfig?> fetchAppConfiguration() async {
    try {
      final data = await AdminPanelService.fetchAppConfig();
      if (data != null) {
        _appConfig = AppConfig.fromJson(data);
        configNotifier.value = _appConfig;
        print('CRITICAL_CONFIG_FETCHED: app_ads=${_appConfig?.ads.map((a) => "${a.adType}:${a.position}:${a.isEnabled}").toList()}');
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cachedConfigKey, jsonEncode(data));
        } catch (_) {}
        debugPrint('[SupabaseService] App config loaded & persisted: ${_appConfig?.appName}');
        return _appConfig;
      }
    } catch (e) {
      debugPrint('[SupabaseService] Fetch app configuration note: $e');
    }
    return _appConfig;
  }

  /// 3. Ping Device & Check Banned Status in `public.app_devices`
  Future<DeviceStatus?> pingDevice() async {
    final appId = _appConfig?.id ?? '5829f424-0129-498c-8e76-3b93fbf63aed';

    try {
      final data = await AdminPanelService.syncDeviceHeartbeat(appId);
      if (data != null) {
        _deviceStatus = DeviceStatus.fromJson(data);
        _deviceId = _deviceStatus!.deviceId;
        debugPrint(
            '[SupabaseService] Device synced. Banned: ${_deviceStatus?.isBanned}, Test Device: ${_deviceStatus?.isTestDevice}');
        return _deviceStatus;
      }
    } catch (e) {
      debugPrint('[SupabaseService] Device ping note: $e');
    }

    _deviceStatus ??= DeviceStatus(
      deviceId: _deviceId.isNotEmpty ? _deviceId : 'dev_offline',
      isBanned: false,
      banReason: '',
      isTestDevice: false,
    );
    return _deviceStatus;
  }

  /// 4. Submit User Feedback to `public.app_feedbacks`
  Future<bool> sendFeedback({
    required String feedbackText,
    int rating = 5,
  }) async {
    final sb = client;
    if (sb == null) return false;

    final currentAppId = _appConfig?.id ?? '5829f424-0129-498c-8e76-3b93fbf63aed';

    try {
      await sb.from('app_feedbacks').insert({
        'app_id': currentAppId,
        'device_id': _deviceId,
        'feedback_text': feedbackText,
        'rating': rating,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('[SupabaseService] Feedback sent to Supabase');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Send feedback note: $e');
      return false;
    }
  }

  /// 5. Submit Rating
  Future<bool> sendRating(int stars) async {
    return sendFeedback(
      feedbackText: 'User rating: $stars / 5 stars',
      rating: stars,
    );
  }
}
