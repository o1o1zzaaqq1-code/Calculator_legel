import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_config.dart';
import 'models/theme_palette.dart';
import 'screens/banned_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/update_dialog.dart';
import 'services/ad_service.dart';
import 'services/history_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set transparent status and navigation bars without borders
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 1. Initialize Supabase Backend & fast-load cached config (takes ~1ms)
  await SupabaseService.instance.initialize();

  // 2. If fresh install without local cache, fetch config quickly so ad keys are present
  if (SupabaseService.instance.appConfig == null) {
    await SupabaseService.instance
        .fetchAppConfiguration()
        .timeout(const Duration(seconds: 3), onTimeout: () => null);
  }

  // 3. Initialize AdService SDK
  await AdService.instance.initialize();

  // 4. Warm up ads immediately in parallel (App Open & Banner preloading)
  AdService.instance.startWarmup();
  // 5. Load saved theme preference
  final themeIndex = await HistoryService.instance.loadThemeIndex();
  final initialPalette = themeIndex < PremiumPalette.allThemes.length
      ? PremiumPalette.allThemes[themeIndex]
      : PremiumPalette.onyxGold;

  runApp(PremiumCalculatorApp(initialPalette: initialPalette));
}

class PremiumCalculatorApp extends StatefulWidget {
  final PremiumPalette initialPalette;

  const PremiumCalculatorApp({super.key, required this.initialPalette});

  @override
  State<PremiumCalculatorApp> createState() => _PremiumCalculatorAppState();
}

class _PremiumCalculatorAppState extends State<PremiumCalculatorApp> {
  late PremiumPalette _currentPalette;

  @override
  void initState() {
    super.initState();
    _currentPalette = widget.initialPalette;
  }

  void _updatePalette(PremiumPalette newPalette) {
    setState(() {
      _currentPalette = newPalette;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: _currentPalette.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _currentPalette.backgroundColor,
        splashColor: _currentPalette.rippleColor,
        highlightColor: Colors.transparent,
        fontFamily: 'Roboto',
      ),
      home: LaunchSplashScreen(
        palette: _currentPalette,
        onPaletteChanged: _updatePalette,
      ),
    );
  }
}

class LaunchSplashScreen extends StatefulWidget {
  final PremiumPalette palette;
  final Function(PremiumPalette) onPaletteChanged;

  const LaunchSplashScreen({
    super.key,
    required this.palette,
    required this.onPaletteChanged,
  });

  @override
  State<LaunchSplashScreen> createState() => _LaunchSplashScreenState();
}

class _LaunchSplashScreenState extends State<LaunchSplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startRemoteControlledFlow();
  }

  /// High-Speed Startup Pipeline:
  /// 1. Immediately kick off App Open Ad loading and Banner preloading
  /// 2. Parallel GET call to Supabase for config update + background ping
  /// 3. Show App Open Ad IMMEDIATELY before opening CalculatorScreen
  /// 4. Once ad is dismissed by user -> open CalculatorScreen with banner preloaded
  Future<void> _startRemoteControlledFlow() async {
    try {
      // Check if previously recorded as banned
      if (SupabaseService.instance.isBanned) {
        _navigateToBanned();
        return;
      }

      // Parallel background fetch for fresh Supabase config
      final freshConfigFuture = SupabaseService.instance
          .fetchAppConfiguration()
          .timeout(const Duration(seconds: 6), onTimeout: () => null);

      // Non-blocking device telemetry
      unawaited(SupabaseService.instance.pingDevice().then((status) {
        if (status != null && status.isBanned && mounted && !_navigated) {
          _navigateToBanned();
        }
      }));

      // Ensure fresh config is loaded first so ads use latest remote position
      await freshConfigFuture;

      // Preload banner in background with fresh config
      AdService.instance.preloadBannerAd();

      // If delay_seconds is configured in Supabase for app_open
      final delaySeconds =
          AdService.instance.getAdConfig('app_open')?.delaySeconds ?? 0;
      if (delaySeconds > 0) {
        await Future.delayed(Duration(seconds: delaySeconds));
      }

      // Instantly load and show App Open Ad full-screen BEFORE opening Calculator
      await AdService.instance.loadAndShowAppOpenAd(
        timeout: const Duration(seconds: 8),
        onDismissed: () {
          _proceedAfterAd(SupabaseService.instance.appConfig);
        },
      );
    } catch (e) {
      debugPrint('[LaunchSplashScreen] Startup note: $e');
      if (mounted && !_navigated) {
        _navigateToHome();
      }
    }
  }

  void _proceedAfterAd(AppConfig? config) {
    if (!mounted || _navigated) return;

    // Check if device is banned
    if (SupabaseService.instance.isBanned) {
      _navigateToBanned();
      return;
    }
    final cfg = config ?? SupabaseService.instance.appConfig;

    // Check if app is in maintenance or inactive
    if (cfg != null && (cfg.isMaintenance || cfg.isInactive)) {
      _navigateToMaintenance(cfg);
      return;
    }

    // Check if app update is required
    if (cfg != null && cfg.isUpdateRequired(SupabaseService.appVersion)) {
      _showUpdateDialog(cfg);
      return;
    }
    _navigateToHome();
  }

  void _navigateToBanned() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeviceBannedScreen(
          banReason: SupabaseService.instance.banReason,
          palette: widget.palette,
        ),
      ),
    );
  }
  void _navigateToMaintenance(AppConfig cfg) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeviceBannedScreen(
          banReason: cfg.isMaintenance
              ? (cfg.updateDescription.isNotEmpty
                  ? cfg.updateDescription
                  : 'App is currently undergoing scheduled maintenance. Please check back shortly.')
              : 'This app service has been deactivated by administrator.',
          palette: widget.palette,
        ),
      ),
    );
  }

  void _showUpdateDialog(AppConfig config) {
    showDialog(
      context: context,
      barrierDismissible: config.isCancelable && !config.forceUpdate,
      builder: (ctx) => UpdateDialog(
        config: config,
        palette: widget.palette,
        onDismiss: () {
          Navigator.of(ctx).pop();
          _navigateToHome();
        },
      ),
    );
  }

  void _navigateToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, _) => CalculatorScreen(
          currentPalette: widget.palette,
          onPaletteChanged: widget.onPaletteChanged,
        ),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.palette.backgroundColor, // Solid color, NO BORDER
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 96,
              height: 96,
            ),
            const SizedBox(height: 18),
            Text(
              'CALCULATOR',
              style: TextStyle(
                color: widget.palette.numTextColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: widget.palette.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
