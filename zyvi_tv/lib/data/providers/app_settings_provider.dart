import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/app_settings_service.dart';

final appSettingsProvider =
    ChangeNotifierProvider<AppSettingsService>((ref) {
  final service = AppSettingsService();
  service.sync();
  ref.onDispose(() => service.dispose());
  return service;
});
