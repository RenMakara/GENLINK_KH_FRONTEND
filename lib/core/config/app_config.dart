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
}
