import 'package:flutter/material.dart';

import '../typography/app_text_theme.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

/// Theme composition folder.
///
/// AppTheme is the only public source for light, dark, and system-aware
/// theme configuration. Avoid hardcoded colors in feature code.
abstract final class AppTheme {
  static ThemeData get light => LightTheme.data();
  static ThemeData get dark => DarkTheme.data();

  /// Theme for a locale code (`en` / `km`) so Khmer picks up its own face.
  static ThemeData lightFor(String languageCode) =>
      LightTheme.data(textTheme: AppTextTheme.forLanguageCode(languageCode));

  static ThemeData darkFor(String languageCode) =>
      DarkTheme.data(textTheme: AppTextTheme.forLanguageCode(languageCode));
}
