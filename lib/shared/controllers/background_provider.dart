import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundState {
  final String? lightPath;
  final String? darkPath;

  const BackgroundState({this.lightPath, this.darkPath});

  static const _unset = Object();

  BackgroundState copyWith({
    Object? lightPath = _unset,
    Object? darkPath = _unset,
  }) {
    return BackgroundState(
      lightPath: identical(lightPath, _unset)
          ? this.lightPath
          : lightPath as String?,
      darkPath: identical(darkPath, _unset)
          ? this.darkPath
          : darkPath as String?,
    );
  }

  String? resolve(Brightness brightness) =>
      brightness == Brightness.dark ? darkPath : lightPath;
}

final backgroundProvider =
    StateNotifierProvider<BackgroundNotifier, BackgroundState>((ref) {
      return BackgroundNotifier()..load();
    });

class BackgroundNotifier extends StateNotifier<BackgroundState> {
  BackgroundNotifier() : super(const BackgroundState());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final light = prefs.getString('background_image_light');
    final dark = prefs.getString('background_image_dark');
    state = BackgroundState(lightPath: light, darkPath: dark);
  }

  Future<void> setLightBackground(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('background_image_light');
    } else {
      await prefs.setString('background_image_light', path);
    }
    state = state.copyWith(lightPath: path);
  }

  Future<void> setDarkBackground(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove('background_image_dark');
    } else {
      await prefs.setString('background_image_dark', path);
    }
    state = state.copyWith(darkPath: path);
  }
}
