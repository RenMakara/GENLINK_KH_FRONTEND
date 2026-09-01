import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/local_storage.dart';

/// Reactive theme mode, persisted locally and mirrored to the backend
/// `Theme` enum (LIGHT / DARK / SYSTEM_DEFAULT).
///
/// The Settings screen writes through [applyBackendTheme]; the backend value
/// stays the source of truth for a signed-in user, while [LocalStorage] keeps
/// the choice across restarts and before the profile call returns.
class ThemeController extends GetxController {
  ThemeController({required LocalStorage localStorage})
    : _storage = localStorage;

  final LocalStorage _storage;

  static const themeLight = 'LIGHT';
  static const themeDark = 'DARK';
  static const themeSystem = 'SYSTEM_DEFAULT';

  final themeMode = ThemeMode.system.obs;

  /// The current mode as the backend `Theme` enum value.
  String get backendTheme => switch (themeMode.value) {
    ThemeMode.light => themeLight,
    ThemeMode.dark => themeDark,
    ThemeMode.system => themeSystem,
  };

  bool get isDark => themeMode.value == ThemeMode.dark;

  /// Load the persisted preference. Call before the first frame.
  Future<void> load() async {
    try {
      final stored = await _storage.readThemeMode();
      if (stored != null) {
        themeMode.value = _toThemeMode(stored);
      }
    } catch (_) {
      // Keep the default ThemeMode.system.
    }
  }

  /// Apply a backend `Theme` enum value (from settings or a profile sync).
  Future<void> applyBackendTheme(String theme) async {
    await setThemeMode(_toThemeMode(theme));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _storage.saveThemeMode(backendTheme);
  }

  /// Convenience for a light/dark switch. A system-mode user flips to the
  /// opposite of whatever is currently rendered.
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
