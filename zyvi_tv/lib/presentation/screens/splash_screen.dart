import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/ad_provider.dart';
import '../../data/providers/channel_provider.dart';
import '../../data/providers/app_settings_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    ref.read(adManagerProvider);

    await Future.delayed(const Duration(seconds: 1));

    final settingsService = ref.read(appSettingsProvider);
    settingsService.onTimestampChanged = () {
      ref.read(allChannelsProvider.notifier).fullSync();
    };

    ref.read(allChannelsProvider.notifier).fullSync();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/splash_screen.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'Zyvi TV',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Live Streaming',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                letterSpacing: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
