/// App configuration folder.
///
/// Store environment flags, build flavor values, app metadata,
/// and configuration objects here.
abstract final class AppConfig {
  static const appName = 'GenLink KH';
  static const tagline = 'Connect. Grow. Thrive.';

  /// Port the Spring Boot server listens on.
  ///
  /// Must match `server.port` in `backend/src/main/resources/application.yaml`
  /// — it is 8888, not the Spring default of 8080.
  static const apiPort = 8888;

  /// Base URL of the GenLink KH API.
  ///
  /// Override at build time without touching code:
  /// ```
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8888
  /// ```
  ///
  /// The default host (`10.0.2.2`) is the Android **emulator's** alias for
  /// the host machine's localhost. It does not resolve anywhere else:
  ///  * physical Android device → use the host's LAN IP, with the phone on
  ///    the same Wi-Fi and the server bound to `0.0.0.0`
  ///  * iOS simulator → `http://localhost:$apiPort`
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:$apiPort',
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
