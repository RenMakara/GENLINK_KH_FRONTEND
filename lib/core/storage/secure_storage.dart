import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for tokens and sensitive session data.
///
/// Uses [FlutterSecureStorage] backed by iOS Keychain / Android Keystore.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  // Keys
  static const _kAccessToken = 'genlink_access_token';
  static const _kRefreshToken = 'genlink_refresh_token';
  static const _kTokenExpiry = 'genlink_token_expiry';
  static const _kUserEmail = 'genlink_user_email';
  static const _kUserId = 'genlink_user_id';

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _memoryFallback[key] = value;
    }
  }

  Future<String?> _read(String key) async {
    try {
      final val = await _storage.read(key: key);
      return val ?? _memoryFallback[key];
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    _memoryFallback.remove(key);
  }

  Future<void> saveAccessToken(String token) => _write(_kAccessToken, token);

  Future<String?> readAccessToken() => _read(_kAccessToken);

  Future<void> saveRefreshToken(String token) => _write(_kRefreshToken, token);

  Future<String?> readRefreshToken() => _read(_kRefreshToken);

  Future<void> saveTokenExpiry(DateTime expiry) =>
      _write(_kTokenExpiry, expiry.toIso8601String());

  Future<DateTime?> readTokenExpiry() async {
    final raw = await _read(_kTokenExpiry);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> saveUserEmail(String email) => _write(_kUserEmail, email);

  Future<String?> readUserEmail() => _read(_kUserEmail);

  Future<void> saveUserId(String id) => _write(_kUserId, id);

  Future<String?> readUserId() => _read(_kUserId);

  /// Store the full token pair from an auth response.
  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveTokenExpiry(DateTime.now().add(const Duration(minutes: 14))),
    ]);
  }

  /// Clear all stored session data.
  Future<void> clearAll() async {
    await _delete(_kAccessToken);
    await _delete(_kRefreshToken);
    await _delete(_kTokenExpiry);
    await _delete(_kUserEmail);
    await _delete(_kUserId);
  }
}
