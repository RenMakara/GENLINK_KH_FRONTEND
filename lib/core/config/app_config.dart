abstract final class AppConfig {
  static const appName = 'GenLink KH';
  static const tagline = 'Connect. Grow. Thrive.';

  static const apiPort = 8888;

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.genlink.enat.online',
  );

  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '456895735825-0jfa3vilbnhsv4hs780822s993f35k0h.apps.googleusercontent.com',
  );

  static bool get isGoogleSignInConfigured => googleServerClientId.isNotEmpty;
}
