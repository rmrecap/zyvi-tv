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
  StreamSubscription<DocumentSnapshot>? _appSettingsSub;

  Future<void> syncAdConfiguration() async {
    try {
      final doc = FirebaseFirestore.instance
          .collection('zyvi_config')
          .doc('monetization');

      final snapshot = await doc.get();
      _applyMonetizationDoc(snapshot);

      _subscription?.cancel();
      _subscription = doc.snapshots().listen(_applyMonetizationDoc);
    } catch (_) {}

    try {
      final appDoc = FirebaseFirestore.instance
          .collection('app_settings')
          .doc('config');

      final appSnapshot = await appDoc.get();
      _applyAppSettingsDoc(appSnapshot);

      _appSettingsSub?.cancel();
      _appSettingsSub = appDoc.snapshots().listen(_applyAppSettingsDoc);
    } catch (_) {}
  }

  void _applyMonetizationDoc(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    appId = data['appId'] as String? ?? appId;
    bannerUnitId = data['bannerUnitId'] as String? ?? bannerUnitId;
    interstitialUnitId =
        data['interstitialUnitId'] as String? ?? interstitialUnitId;
    adsEnabled = data['adsEnabled'] as bool? ?? adsEnabled;

    _checkInitialized();
  }

  void _applyAppSettingsDoc(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final settingsAppId = data['adMobAppId'] as String?;
    final settingsBannerId = data['adMobBannerUnitId'] as String?;
    final settingsInterstitialId = data['adMobInterstitialUnitId'] as String?;
    final settingsAdsEnabled = data['adsEnabled'] as bool?;

    if (settingsAppId != null && settingsAppId.isNotEmpty) {
      appId = settingsAppId;
    }
    if (settingsBannerId != null && settingsBannerId.isNotEmpty) {
      bannerUnitId = settingsBannerId;
    }
    if (settingsInterstitialId != null && settingsInterstitialId.isNotEmpty) {
      interstitialUnitId = settingsInterstitialId;
    }
    if (settingsAdsEnabled != null) {
      adsEnabled = settingsAdsEnabled;
    }

    _checkInitialized();
  }

  void _checkInitialized() {
    if (!initialized && appId.isNotEmpty) {
      initialized = true;
    }
    notifyListeners();
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
    _appSettingsSub?.cancel();
    _interstitial?.dispose();
    super.dispose();
  }
}
