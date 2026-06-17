import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/ad_provider.dart';

class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadBanner();
    }
  }

  void _loadBanner() {
    final adManager = ref.read(adManagerProvider);
    if (!adManager.canShowBanner) return;

    BannerAd(
      adUnitId: adManager.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _banner = ad as BannerAd);
          debugPrint('AdMob: Banner loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('AdMob: Banner failed to load: ${error.message}');
        },
        onAdOpened: (_) => debugPrint('AdMob: Banner opened'),
        onAdClosed: (_) => debugPrint('AdMob: Banner closed'),
      ),
    ).load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adManager = ref.watch(adManagerProvider);
    final showAd = adManager.canShowBanner && _banner != null;

    return Container(
      width: double.infinity,
      height: 60,
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '— Sponsor —',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: showAd
                ? Center(child: AdWidget(ad: _banner!))
                : Center(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.microBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'Ad Space Available',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
