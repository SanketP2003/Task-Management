import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  late SharedPreferences _prefs;

  @override
  Future<ThemeMode> build() async {
    _prefs = await SharedPreferences.getInstance();
    final storedMode = _prefs.getString(_themeModeKey);

    switch (storedMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    await _prefs.setString(_themeModeKey, _encodeThemeMode(mode));
  }

  Future<void> toggleTheme() async {
    final currentMode = state.valueOrNull ?? ThemeMode.light;
    final nextMode =
        currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  String _encodeThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
  }
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
