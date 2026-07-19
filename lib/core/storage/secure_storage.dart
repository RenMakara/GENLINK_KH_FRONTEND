import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for tokens and sensitive session data.
///
/// Uses [FlutterSecureStorage] backed by iOS Keychain / Android Keystore.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Keys
  static const _kAccessToken = 'genlink_access_token';
  static const _kRefreshToken = 'genlink_refresh_token';
  static const _kTokenExpiry = 'genlink_token_expiry';
  static const _kUserEmail = 'genlink_user_email';
  static const _kUserId = 'genlink_user_id';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);

  Future<String?> readAccessToken() =>
      _storage.read(key: _kAccessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefreshToken, value: token);

  Future<String?> readRefreshToken() =>
      _storage.read(key: _kRefreshToken);

  Future<void> saveTokenExpiry(DateTime expiry) =>
      _storage.write(key: _kTokenExpiry, value: expiry.toIso8601String());

  Future<DateTime?> readTokenExpiry() async {
    final raw = await _storage.read(key: _kTokenExpiry);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> saveUserEmail(String email) =>
      _storage.write(key: _kUserEmail, value: email);

  Future<String?> readUserEmail() =>
      _storage.read(key: _kUserEmail);

  Future<void> saveUserId(String id) =>
      _storage.write(key: _kUserId, value: id);

  Future<String?> readUserId() =>
      _storage.read(key: _kUserId);

  /// Store the full token pair from an auth response.
  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      // JWT access tokens are typically short-lived; store a 15-min window
      // for proactive refresh. The backend controls actual expiry.
      saveTokenExpiry(DateTime.now().add(const Duration(minutes: 14))),
    ]);
  }

  /// Clear all stored session data.
  Future<void> clearAll() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kTokenExpiry);
    await _storage.delete(key: _kUserEmail);
    await _storage.delete(key: _kUserId);
  }
}
