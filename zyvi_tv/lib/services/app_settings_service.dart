import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettings {
  final String logoUrl;
  final int primaryColor;
  final int secondaryColor;
  final String bannerUrl;
  final String adMobAppId;
  final String adMobBannerUnitId;
  final String adMobInterstitialUnitId;
  final bool adsEnabled;
  final DateTime? lastUpdatedTimestamp;

  const AppSettings({
    this.logoUrl = '',
    this.primaryColor = 0xFF7F00FF,
    this.secondaryColor = 0xFFE100FF,
    this.bannerUrl = '',
    this.adMobAppId = '',
    this.adMobBannerUnitId = '',
    this.adMobInterstitialUnitId = '',
    this.adsEnabled = false,
    this.lastUpdatedTimestamp,
  });

  factory AppSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AppSettings();
    DateTime? parsedTs;
    final ts = data['last_updated_timestamp'];
    if (ts is Timestamp) {
      parsedTs = ts.toDate();
    } else if (ts is String) {
      parsedTs = DateTime.tryParse(ts);
    }
    return AppSettings(
      logoUrl: data['logoUrl'] as String? ?? '',
      primaryColor: _parseColor(data['primaryColor'], 0xFF7F00FF),
      secondaryColor: _parseColor(data['secondaryColor'], 0xFFE100FF),
      bannerUrl: data['bannerUrl'] as String? ?? '',
      adMobAppId: data['adMobAppId'] as String? ?? '',
      adMobBannerUnitId: data['adMobBannerUnitId'] as String? ?? '',
      adMobInterstitialUnitId:
          data['adMobInterstitialUnitId'] as String? ?? '',
      adsEnabled: data['adsEnabled'] as bool? ?? false,
      lastUpdatedTimestamp: parsedTs,
    );
  }

  static int _parseColor(dynamic value, int defaultColor) {
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value.replaceFirst('#', '0xFF'));
      } catch (_) {
        return defaultColor;
      }
    }
    return defaultColor;
  }
}

class AppSettingsService extends ChangeNotifier {
  AppSettings _settings = const AppSettings();
  StreamSubscription<DocumentSnapshot>? _subscription;
  VoidCallback? onTimestampChanged;

  AppSettings get settings => _settings;

  Future<void> sync() async {
    try {
      final doc = FirebaseFirestore.instance
          .collection('app_settings')
          .doc('config');

      final snapshot = await doc.get();
      _apply(snapshot);

      _subscription?.cancel();
      _subscription = doc.snapshots().listen(_apply);
    } catch (_) {}
  }

  void _apply(DocumentSnapshot snapshot) {
    final oldTs = _settings.lastUpdatedTimestamp;
    _settings = AppSettings.fromMap(snapshot.data() as Map<String, dynamic>?);
    final newTs = _settings.lastUpdatedTimestamp;
    if (oldTs != null && newTs != null && newTs.isAfter(oldTs)) {
      onTimestampChanged?.call();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
