import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/theme_palette.dart';
import '../services/ad_service.dart';
import '../services/supabase_service.dart';

class BannerAdWidget extends StatefulWidget {
  final PremiumPalette palette;

  const BannerAdWidget({
    super.key,
    required this.palette,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  @override
  void initState() {
    super.initState();
    SupabaseService.instance.configNotifier.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    SupabaseService.instance.configNotifier.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    if (mounted) {
      setState(() {});
      if (AdService.instance.isSupportedPlatform &&
          AdService.instance.isAdEnabled('banner') &&
          !AdService.instance.isPersistentBannerLoaded &&
          !AdService.instance.isLoadingPersistentBanner) {
        final width = MediaQuery.of(context).size.width.truncate();
        AdService.instance.loadPersistentBanner(width: width);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AdService.instance.isSupportedPlatform &&
        AdService.instance.isAdEnabled('banner') &&
        !AdService.instance.isPersistentBannerLoaded &&
        !AdService.instance.isLoadingPersistentBanner) {
      final width = MediaQuery.of(context).size.width.truncate();
      AdService.instance.loadPersistentBanner(width: width);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.instance.isSupportedPlatform ||
        !AdService.instance.isAdEnabled('banner')) {
      return const SizedBox.shrink();
    }

    if (!AdService.instance.isPersistentBannerLoaded &&
        !AdService.instance.isLoadingPersistentBanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final width = MediaQuery.of(context).size.width.truncate();
          AdService.instance.loadPersistentBanner(width: width);
        }
      });
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.bannerLoadedNotifier,
      builder: (context, isLoaded, _) {
        final banner = AdService.instance.persistentBannerAd;
        if (isLoaded && banner != null) {
          return Container(
            width: double.infinity,
            height: banner.size.height.toDouble(),
            alignment: Alignment.center,
            color: widget.palette.backgroundColor, // strictly solid, NO gradients
            child: SizedBox(
              width: banner.size.width.toDouble(),
              height: banner.size.height.toDouble(),
              child: AdWidget(ad: banner),
            ),
          );
        }

        // Steady layout while loading with full-width solid background
        return Container(
          width: double.infinity,
          height: 50,
          color: widget.palette.backgroundColor,
        );
      },
    );
  }
}
