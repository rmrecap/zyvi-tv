import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'data/models/channel_model.dart';
import 'firebase_options.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/video_player_view.dart';
import 'presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: ZyviTVApp()));
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
