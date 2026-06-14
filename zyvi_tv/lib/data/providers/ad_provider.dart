import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ad_manager_service.dart';

final adManagerProvider = ChangeNotifierProvider<AdManagerService>((ref) {
  final service = AdManagerService();
  service.syncAdConfiguration();
  ref.onDispose(() => service.dispose());
  return service;
});
