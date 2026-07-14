import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

/// Theme composition folder.
///
/// AppTheme is the only public source for light, dark, and system-aware
/// theme configuration. Avoid hardcoded colors in feature code.
abstract final class AppTheme {
  static ThemeData get light => LightTheme.data;
  static ThemeData get dark => DarkTheme.data;
}
