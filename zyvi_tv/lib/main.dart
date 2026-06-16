import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/channel_model.dart';
import 'data/providers/channel_repository.dart';
import 'firebase_options.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/video_player_view.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/category_channels_screen.dart';
import 'services/hive_cache_service.dart';

late final HiveCacheService hiveCacheService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ChannelModelAdapter());
    Hive.registerAdapter(StreamSourceAdapter());
    await Hive.openBox<ChannelModel>(kChannelBox);
    hiveCacheService = HiveCacheService();
    await hiveCacheService.init();
    final cached = hiveCacheService.getCachedChannelCount();
    debugPrint('Hive cache ready: $cached channels');
  } catch (e) {
    debugPrint('Hive init error: $e');
  }
  runApp(const ProviderScope(child: ZyviTVApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await MobileAds.instance.initialize();
      final deviceId = await _getTestDeviceId();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: [deviceId]),
      );
      debugPrint('AdMob initialized: $deviceId');
    } catch (e) {
      debugPrint('AdMob deferred init error: $e');
    }
  });
}

Future<String> _getTestDeviceId() async {
  try {
    final info = await MobileAds.instance.getRequestConfiguration();
    final ids = info.testDeviceIds;
    if (ids != null && ids.isNotEmpty) {
      return ids.first;
    }
    return 'DEVICE_ID_EMULATOR';
  } catch (_) {
    return 'DEVICE_ID_EMULATOR';
  }
}

class ZyviTVApp extends StatelessWidget {
  const ZyviTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zyvi TV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
          case '/player':
            final source = settings.arguments as StreamSource;
            return MaterialPageRoute(
              builder: (_) => VideoPlayerView(source: source),
            );
          case '/category-detail':
            final category = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => CategoryChannelsScreen(category: category),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
        }
      },
    );
  }
}
