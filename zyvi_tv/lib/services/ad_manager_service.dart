import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManagerService extends ChangeNotifier {
  String appId = '';
  String bannerUnitId = '';
  String interstitialUnitId = '';
  bool adsEnabled = false;
  bool initialized = false;

  InterstitialAd? _interstitial;

  StreamSubscription<DocumentSnapshot>? _subscription;

  Future<void> syncAdConfiguration() async {
    final doc = FirebaseFirestore.instance
        .collection('zyvi_config')
        .doc('monetization');

    final snapshot = await doc.get();
    _applyDocument(snapshot);

    _subscription?.cancel();
    _subscription = doc.snapshots().listen(_applyDocument);
  }

  void _applyDocument(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    appId = data['appId'] as String? ?? '';
    bannerUnitId = data['bannerUnitId'] as String? ?? '';
    interstitialUnitId = data['interstitialUnitId'] as String? ?? '';
    adsEnabled = data['adsEnabled'] as bool? ?? false;

    if (!initialized && appId.isNotEmpty) {
      _initMobileAds();
    }

    notifyListeners();
  }

  Future<void> _initMobileAds() async {
    try {
      await MobileAds.instance.initialize();
      initialized = true;
      notifyListeners();
    } catch (_) {}
  }

  bool get canShowBanner =>
      adsEnabled && bannerUnitId.isNotEmpty && initialized;
  bool get canShowInterstitial =>
      adsEnabled && interstitialUnitId.isNotEmpty && initialized;

  Future<void> loadInterstitial() async {
    await _interstitial?.dispose();
    _interstitial = null;

    if (!canShowInterstitial) return;

    await InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          notifyListeners();
        },
        onAdFailedToLoad: (_) {
          _interstitial = null;
          notifyListeners();
        },
      ),
    );
  }

  Future<void> showInterstitialIfAvailable({
    VoidCallback? onDismissed,
  }) async {
    final ad = _interstitial;
    _interstitial = null;

    if (ad == null) {
      onDismissed?.call();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        onDismissed?.call();
      },
    );
    ad.show();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _interstitial?.dispose();
    super.dispose();
  }
}
