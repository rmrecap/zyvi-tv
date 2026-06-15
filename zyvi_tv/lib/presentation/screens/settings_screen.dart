import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/ad_banner_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (user != null) ...[
                    Container(
                      decoration: AppTheme.glassCardDecoration(radius: 16),
                      child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppTheme.accentPurple,
                                child: Text(
                                  user.email?.isNotEmpty == true
                                      ? user.email![0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName ?? 'User',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      user.email ?? '',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                  ],
                  _sectionHeader('Playback'),
                  _settingTile(Icons.hd, 'Default Quality', 'Auto'),
                  _settingTile(Icons.wifi, 'Cellular Streaming', 'Ask me'),
                  _settingTile(Icons.storage, 'Cache Size', '1.2 GB'),
                  const SizedBox(height: 28),
                  _sectionHeader('About'),
                  _settingTile(Icons.info, 'Version', '1.0.0'),
                  _settingTile(Icons.description, 'Licenses', ''),
                ],
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: AppTheme.glassCardDecoration(radius: 14),
      child: ListTile(
          leading: Icon(icon, color: AppTheme.accentPurple),
          title: Text(
            title,
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          trailing: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary),
                )
              : const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondary),
        ),
    );
  }
}
