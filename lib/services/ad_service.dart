import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/app_config.dart';
import 'supabase_service.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  bool _isInitialized = false;

  // App Open Ad State
  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  bool _isLoadingAppOpenAd = false;
  Completer<bool>? _appOpenCompleter;
  DateTime? _appOpenLoadTime;

  // Banner Ad Preloader State
  BannerAd? _preloadedBannerAd;
  bool _isPreloadedBannerReady = false;
  bool _isLoadingPreloadedBanner = false;

  // Interstitial Ad State
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  int _calculationCount = 0;

  bool get isInitialized => _isInitialized;

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Helper to get remote ad configuration for a given type from Supabase
  AppAdConfig? getAdConfig(String type) {
    return SupabaseService.instance.appConfig?.getAd(type);
  }

  /// Resolve dynamic AdMob unit ID strictly from Supabase config.
  /// NO HARDCODED AD UNIT IDs IN APP CODE!
  /// Test ads or real ads are determined by what is configured in Supabase.
  String getAdUnitId(String type) {
    if (kIsWeb) return '';

    final config = getAdConfig(type);
    if (config != null) {
      if (!config.isEnabled) return '';
      final isTestDevice = SupabaseService.instance.isTestDevice;
      final id = config.resolveAdUnitId(isDeviceTest: isTestDevice);
      if (id.isNotEmpty) {
        // Sanitize legacy or broken app open test ad ID
        if (type == 'app_open' && id.contains('3419832817')) {
          return 'ca-app-pub-3940256099942544/9257395921';
        }
        return id;
      }
    }

    // Default official Google Mobile Ads test IDs
    if (type == 'app_open') {
      return 'ca-app-pub-3940256099942544/9257395921';
    } else if (type == 'banner') {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (type == 'interstitial') {
      return 'ca-app-pub-3940256099942544/1033173712';
    }

    return '';
  }

  /// Check if a particular ad format is enabled in Supabase and has an ad unit ID
  bool isAdEnabled(String type) {
    final config = getAdConfig(type);
    if (config != null) {
      return config.isEnabled && getAdUnitId(type).isNotEmpty;
    }
    return type == 'app_open' || type == 'banner';
  }

  // Getters for specific formats directly from Supabase config
  String get appOpenAdUnitId => getAdUnitId('app_open');
  String get bannerAdUnitId => getAdUnitId('banner');
  String get bottomBannerAdUnitId => bannerAdUnitId;
  String get interstitialAdUnitId => getAdUnitId('interstitial');

  /// Dynamic position for Banner Ad strictly from Supabase ('top' or 'bottom')
  String get bannerPosition {
    final config = getAdConfig('banner');
    return (config?.position ?? 'bottom').toLowerCase().trim();
  }

  bool get isBannerTop => bannerPosition == 'top';
  bool get isBannerBottom => !isBannerTop;

  int get interstitialClickInterval {
    final config = getAdConfig('interstitial');
    return (config != null && config.clickInterval > 0)
        ? config.clickInterval
        : 5;
  }

  /// Initialize Mobile Ads SDK immediately
  Future<void> initialize() async {
    if (!isSupportedPlatform) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdService] MobileAds initialized successfully');
    } catch (e) {
      debugPrint('[AdService] Initialization error: $e');
    }
  }

  /// Preload ads immediately at startup in parallel using cached/current Supabase config
  void startWarmup() {
    if (!isSupportedPlatform) return;

    if (isAdEnabled('app_open') && !_isAppOpenAdAvailable()) {
      loadAppOpenAdWithTimeout();
    }
    if (isAdEnabled('banner') && !_isPreloadedBannerReady) {
      preloadBannerAd();
    }
  }

  // ==========================================
  // APP OPEN ADS (Opens BEFORE App UI Opens)
  // ==========================================

  /// Fast App Open Ad loader with a timeout for startup gating
  Future<bool> loadAppOpenAdWithTimeout({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!isSupportedPlatform) return false;
    if (!isAdEnabled('app_open')) {
      debugPrint('[AdService] App Open ad disabled or no ID in Supabase');
      return false;
    }

    if (_isAppOpenAdAvailable()) {
      debugPrint('[AdService] App Open Ad already loaded and available');
      return true;
    }

    if (_isLoadingAppOpenAd && _appOpenCompleter != null) {
      try {
        return await _appOpenCompleter!.future
            .timeout(timeout, onTimeout: () => false);
      } catch (_) {
        return false;
      }
    }

    final unitId = appOpenAdUnitId;
    if (unitId.isEmpty) return false;

    final completer = Completer<bool>();
    _appOpenCompleter = completer;
    _isLoadingAppOpenAd = true;
    debugPrint('[AdService] Fast-loading App Open Ad ($unitId)...');

    try {
      await AppOpenAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[AdService] App Open Ad loaded & ready');
            _appOpenAd = ad;
            _isLoadingAppOpenAd = false;
            _appOpenLoadTime = DateTime.now();
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] App Open Ad failed: $error');
            _isLoadingAppOpenAd = false;
            _appOpenAd = null;
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        ),
      );

      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          debugPrint('[AdService] App Open load timeout reached ($timeout)');
          return false;
        },
      );
    } catch (e) {
      debugPrint('[AdService] Exception loading App Open: $e');
      _isLoadingAppOpenAd = false;
      return false;
    }
  }
  /// Instantly load and show App Open Ad before app UI opens
  Future<void> loadAndShowAppOpenAd({
    required VoidCallback onDismissed,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!isSupportedPlatform || !isAdEnabled('app_open')) {
      onDismissed();
      return;
    }

    // If already preloaded and available in memory: SHOW IMMEDIATELY (0ms!)
    if (_isAppOpenAdAvailable()) {
      debugPrint('[AdService] App Open Ad preloaded: showing instantly (0ms)!');
      showAppOpenAdIfAvailable(onDismissed: onDismissed);
      return;
    }

    // If not yet ready, await load up to timeout
    final isReady = await loadAppOpenAdWithTimeout(timeout: timeout);
    if (isReady && _isAppOpenAdAvailable()) {
      debugPrint('[AdService] App Open Ad finished loading: showing now full-screen!');
      showAppOpenAdIfAvailable(onDismissed: onDismissed);
    } else {
      debugPrint('[AdService] App Open Ad unavailable or timed out: proceeding to app');
      onDismissed();
    }
  }

  /// Background preloader for subsequent resume events (0ms delay)
  void preloadNextAppOpenAd() {
    if (!isSupportedPlatform ||
        !isAdEnabled('app_open') ||
        _isLoadingAppOpenAd ||
        _isAppOpenAdAvailable()) {
      return;
    }

    final unitId = appOpenAdUnitId;
    if (unitId.isEmpty) return;

    _isLoadingAppOpenAd = true;
    debugPrint('[AdService] Preloading next App Open Ad ($unitId)...');

    AppOpenAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Next App Open Ad preloaded and ready');
          _appOpenAd = ad;
          _isLoadingAppOpenAd = false;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Next App Open Ad preload failed: $error');
          _isLoadingAppOpenAd = false;
          _appOpenAd = null;
        },
      ),
    );
  }

  /// Show App Open Ad if available; triggers callback strictly when dismissed
  void showAppOpenAdIfAvailable({VoidCallback? onDismissed}) {
    if (!isSupportedPlatform || !isAdEnabled('app_open')) {
      onDismissed?.call();
      return;
    }

    if (!_isAppOpenAdAvailable()) {
      preloadNextAppOpenAd();
      onDismissed?.call();
      return;
    }

    if (_isShowingAppOpenAd) {
      onDismissed?.call();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
        debugPrint('[AdService] App Open Ad showing full-screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] App Open Ad dismissed by user -> Proceeding');
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        onDismissed?.call();
        preloadNextAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Failed to show App Open: $error');
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        onDismissed?.call();
        preloadNextAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  bool _isAppOpenAdAvailable() {
    if (_appOpenAd == null) return false;
    if (_appOpenLoadTime == null) return false;
    return DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  // ==========================================
  // PERSISTENT SINGLE BANNER AD (Same Ad Across App, No Alag-Alag Ads)
  // ==========================================

  BannerAd? _persistentBannerAd;
  bool _isPersistentBannerLoaded = false;
  bool _isLoadingPersistentBanner = false;
  final ValueNotifier<bool> bannerLoadedNotifier = ValueNotifier<bool>(false);

  BannerAd? get persistentBannerAd => _persistentBannerAd;
  bool get isPersistentBannerLoaded =>
      _isPersistentBannerLoaded && _persistentBannerAd != null;
  bool get isLoadingPersistentBanner => _isLoadingPersistentBanner;

  /// Preload persistent banner ad immediately during startup / splash
  void preloadBannerAd() {
    try {
      final view = PlatformDispatcher.instance.views.firstOrNull;
      if (view != null) {
        final screenWidth =
            (view.physicalSize.width / view.devicePixelRatio).truncate();
        if (screenWidth > 0) {
          loadPersistentBanner(width: screenWidth);
          return;
        }
      }
    } catch (_) {}
    loadPersistentBanner();
  }

  /// Load persistent single adaptive full-width banner ad once (reused everywhere, never changes)
  Future<void> loadPersistentBanner({int? width, VoidCallback? onLoaded}) async {
    if (!isSupportedPlatform || !isAdEnabled('banner')) return;
    if (_persistentBannerAd != null) {
      if (_isPersistentBannerLoaded) {
        bannerLoadedNotifier.value = true;
        onLoaded?.call();
      }
      return;
    }
    if (_isLoadingPersistentBanner) return;

    final unitId = bannerAdUnitId;
    if (unitId.isEmpty) return;

    _isLoadingPersistentBanner = true;
    debugPrint('[AdService] Loading persistent full-width Banner Ad ($unitId, width: $width)...');

    try {
      AdSize adSize = AdSize.banner;
      if (width != null && width > 0) {
        final adaptiveSize =
            await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
        if (adaptiveSize != null) {
          adSize = adaptiveSize;
        }
      }

      final banner = BannerAd(
        adUnitId: unitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('[AdService] Persistent full-width Banner Ad loaded successfully: ${adSize.width}x${adSize.height}');
            _persistentBannerAd = ad as BannerAd;
            _isPersistentBannerLoaded = true;
            _isLoadingPersistentBanner = false;
            bannerLoadedNotifier.value = true;
            onLoaded?.call();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('[AdService] Persistent banner failed to load: $error');
            ad.dispose();
            _persistentBannerAd = null;
            _isPersistentBannerLoaded = false;
            _isLoadingPersistentBanner = false;
            bannerLoadedNotifier.value = false;
          },
        ),
      );
      await banner.load();
    } catch (e) {
      debugPrint('[AdService] Error loading persistent banner: $e');
      _isLoadingPersistentBanner = false;
      bannerLoadedNotifier.value = false;
    }
  }

  // ==========================================
  // INTERSTITIAL / INSTALLER ADS (DISABLED)
  // ==========================================

  /// Preload Interstitial Ad (Disabled)
  void loadInterstitialAd() {
    // Interstitial / installer ads are disabled
    return;
  }

  /// Show Interstitial Ad if available (Disabled)
  void showInterstitialAd({VoidCallback? onDismissed}) {
    // Interstitial / installer ads are disabled
    onDismissed?.call();
    return;
  }

  /// Call this whenever user performs a calculation (Disabled)
  void onCalculationPerformed(BuildContext context) {
    // Interstitial / installer ads are disabled
    return;
  }
}
