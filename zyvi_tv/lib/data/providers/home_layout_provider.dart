import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

const List<String> _defaultSectionOrder = [
  'banner_slider',
  'live_now',
  'categories',
  'trending',
];

final homeLayoutProvider = FutureProvider<List<String>>((ref) async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setDefaults({
      'home_section_order': jsonEncode(_defaultSectionOrder),
    });
    await remoteConfig.fetchAndActivate().timeout(const Duration(seconds: 2));
    final raw = remoteConfig.getString('home_section_order');
    if (raw.isEmpty) return _defaultSectionOrder;
    final parsed = jsonDecode(raw);
    if (parsed is! List) return _defaultSectionOrder;
    return parsed.cast<String>();
  } catch (_) {
    return _defaultSectionOrder;
  }
});
