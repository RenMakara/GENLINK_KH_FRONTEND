/// App configuration folder.
///
/// Store environment flags, build flavor values, app metadata,
/// and configuration objects here.
abstract final class AppConfig {
  static const appName = 'GenLink KH';
  static const tagline = 'Connect. Grow. Thrive.';

  /// The Spring Boot server's own port. Only relevant when talking to it
  /// DIRECTLY (local development). In production the client never uses this:
  /// it hits Nginx on port 80, which proxies to 8888 internally.
  static const apiPort = 8888;

  /// Base URL of the GenLink KH API.
  ///
  /// Defaults to the **deployed server** — reached through Nginx on port 80,
  /// so no port in the URL. A plain `flutter run` or the IDE Run button hits
  /// production with no flags.
  ///
  /// Override for LOCAL development against a backend on your own machine:
  /// ```
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:$apiPort         # emulator
  /// flutter run --dart-define=API_BASE_URL=http://192.168.0.108:$apiPort    # device on LAN
  /// ```
  ///
  /// ⚠️ This default is plain `http://`. Android and iOS block cleartext HTTP
  /// in RELEASE builds, so it works in DEBUG only (the debug Android manifest
  /// opts in to cleartext). A shippable release build needs the HTTPS domain —
  /// when `api.genlinkkh.com` is live, change this default to
  /// `https://api.genlinkkh.com` and cleartext is no longer involved.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://18.143.33.191',
    // defaultValue: 'http://localhost:8888',
  );

  /// OAuth **Web** client id, passed to Google Sign-In as `serverClientId`.
  ///
  /// This must be the *Web* client, not the Android one: on Android the ID
  /// token's `aud` claim is the serverClientId, and the backend's
  /// `GoogleTokenVerifier` checks exactly that. Using the Android client id
  /// here makes every token fail verification with
  /// `AUTH_INVALID_GOOGLE_TOKEN`.
  ///
  /// The same value must appear in the backend's `GOOGLE_CLIENT_ID`.
  ///
  /// Defaulted rather than left empty so a plain `flutter run` — or the IDE's
  /// Run button — works with no flags. An OAuth **client id is not a secret**:
  /// it ships inside every copy of the app and is visible to anyone who
  /// unpacks the APK. The client *secret* is the sensitive half, and this
  /// flow never uses it.
  ///
  /// Override per developer without editing code:
  /// ```
  /// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
  /// ```
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '456895735825-0jfa3vilbnhsv4hs780822s993f35k0h.apps.googleusercontent.com',
  );

  static bool get isGoogleSignInConfigured => googleServerClientId.isNotEmpty;
}
