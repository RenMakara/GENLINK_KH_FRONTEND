import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Text theme folder.
///
/// Build Material text themes here so features consume typography through
/// Theme.of(context).textTheme.
abstract final class AppTextTheme {
  static const english = TextTheme(
    bodyMedium: TextStyle(fontFamily: AppTypography.englishFontFamily),
  );

  static const khmer = TextTheme(
    bodyMedium: TextStyle(fontFamily: AppTypography.khmerFontFamily),
  );
}
