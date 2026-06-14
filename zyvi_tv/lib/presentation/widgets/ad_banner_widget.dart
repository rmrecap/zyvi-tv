import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/providers/ad_provider.dart';

class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _banner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBanner();
  }

  void _loadBanner() {
    _banner?.dispose();
    _banner = null;

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
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
        },
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

    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
