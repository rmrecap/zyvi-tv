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
    if (!adManager.canShowBanner || _banner == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 50,
      color: AppTheme.surface,
      child: Center(
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}
