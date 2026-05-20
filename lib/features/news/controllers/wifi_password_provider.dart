import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/news/controllers/wifi_password_controller.dart';
import 'package:jup/features/news/models/wifi_password_model.dart';
import 'package:jup/main.dart';
import 'package:jup/shared/services/api_client.dart';

/// Provider for the WifiPasswordController
final wifiPasswordControllerProvider = Provider<WifiPasswordController>((ref) {
  final client = ref.watch(strapiClientProvider);
  final prefs = ref.watch(sharedPreferenceProviderGlobal);
  return WifiPasswordController(client, prefs);
});

/// Provider for fetching the WiFi password
final wifiPasswordProvider = FutureProvider<WifiPassword>((ref) async {
  final controller = ref.watch(wifiPasswordControllerProvider);
  return await controller.fetchWifiPassword();
});
