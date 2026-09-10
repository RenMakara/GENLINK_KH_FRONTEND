import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/local_storage.dart';

class ThemeController extends GetxController {
  ThemeController({required LocalStorage localStorage})
    : _storage = localStorage;

  final LocalStorage _storage;

  static const themeLight = 'LIGHT';
  static const themeDark = 'DARK';
  static const themeSystem = 'SYSTEM_DEFAULT';

  final themeMode = ThemeMode.system.obs;

  String get backendTheme => switch (themeMode.value) {
    ThemeMode.light => themeLight,
    ThemeMode.dark => themeDark,
    ThemeMode.system => themeSystem,
  };

  bool get isDark => themeMode.value == ThemeMode.dark;

  Future<void> load() async {
    try {
      final stored = await _storage.readThemeMode();
      if (stored != null) {
        themeMode.value = _toThemeMode(stored);
      }
    } catch (_) {
    }
  }

  Future<void> applyBackendTheme(String theme) async {
    await setThemeMode(_toThemeMode(theme));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _storage.saveThemeMode(backendTheme);
  }

  Future<void> toggle(BuildContext context) async {
    final effectiveDark = switch (themeMode.value) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    await setThemeMode(effectiveDark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _toThemeMode(String backendValue) => switch (backendValue) {
    themeLight => ThemeMode.light,
    themeDark => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
