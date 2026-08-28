/// Radius token folder.
///
/// Store border radius values here so widgets avoid one-off radius choices.
abstract final class AppRadius {
  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 16.0;

  /// Cards and sheets that read as a single large surface.
  static const xl = 24.0;

  /// Squircle used by OTP boxes, avatars-in-a-square, and small tiles.
  static const squircle = 20.0;

  static const pill = 999.0;

  static const plateRatio = 107 / 321;
}
