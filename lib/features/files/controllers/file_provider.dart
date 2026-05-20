import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/files/controllers/file_controller.dart';
import 'package:jup/features/files/models/file_model.dart';
import 'package:jup/shared/services/api_client.dart';

/// Provider for the StrapiFileController
final fileControllerProvider = Provider<StrapiFileController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return StrapiFileController(client);
});

/// Provider for fetching avatar files
final avatarsProvider = FutureProvider<List<StrapiFile>>((ref) async {
  final controller = ref.watch(fileControllerProvider);
  return await controller.getAvatars();
});
