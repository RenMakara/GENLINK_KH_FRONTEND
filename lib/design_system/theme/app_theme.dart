import 'package:flutter/material.dart';

import '../typography/app_text_theme.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

abstract final class AppTheme {
  static ThemeData get light => LightTheme.data();
  static ThemeData get dark => DarkTheme.data();

  static ThemeData lightFor(String languageCode) =>
      LightTheme.data(textTheme: AppTextTheme.forLanguageCode(languageCode));

  static ThemeData darkFor(String languageCode) =>
      DarkTheme.data(textTheme: AppTextTheme.forLanguageCode(languageCode));
}
