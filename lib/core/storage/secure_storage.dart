import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  // The in-memory value is authoritative for this app session. This avoids a
  // stale platform-keystore read winning immediately after a write.
  final Map<String, String> _memoryFallback = {};
  final Set<String> _deletedKeys = {};
  Future<void> _operationTail = Future<void>.value();

  static const _kAccessToken = 'genlink_access_token';
  static const _kRefreshToken = 'genlink_refresh_token';
  static const _kTokenExpiry = 'genlink_token_expiry';
  static const _kUserEmail = 'genlink_user_email';
  static const _kUserId = 'genlink_user_id';

  Future<T> _exclusive<T>(Future<T> Function() operation) {
    final next = _operationTail.then((_) => operation());
    _operationTail = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<void> _write(String key, String value) => _exclusive(() async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      // Keep this session usable even when the platform keystore is
      // temporarily unavailable.
      debugPrint('[STORAGE] Secure write failed for $key: $error');
    }
    _memoryFallback[key] = value;
    _deletedKeys.remove(key);
  });

  Future<String?> _read(String key) => _exclusive(() async {
    // A fallback value represents a successful logical write even if the
    // platform keystore rejected it. Never let a stale platform value win.
    final fallback = _memoryFallback[key];
    if (fallback != null) return fallback;
    if (_deletedKeys.contains(key)) return null;

    try {
      return await _storage.read(key: key);
    } catch (error) {
      debugPrint('[STORAGE] Secure read failed for $key: $error');
      return null;
    }
  });

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

  Future<void> saveTokenPair({
    required String accessToken,
    required String refreshToken,
  }) => _exclusive(() async {
    await _writeUnlocked(_kAccessToken, accessToken);
    await _writeUnlocked(_kRefreshToken, refreshToken);
    await _writeUnlocked(
      _kTokenExpiry,
      DateTime.now().add(const Duration(minutes: 14)).toIso8601String(),
    );
  });

  Future<void> clearAll() => _exclusive(() async {
    await _deleteUnlocked(_kAccessToken);
    await _deleteUnlocked(_kRefreshToken);
    await _deleteUnlocked(_kTokenExpiry);
    await _deleteUnlocked(_kUserEmail);
    await _deleteUnlocked(_kUserId);
  });

  Future<void> _writeUnlocked(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      debugPrint('[STORAGE] Secure write failed for $key: $error');
    }
    _memoryFallback[key] = value;
    _deletedKeys.remove(key);
  }

  Future<void> _deleteUnlocked(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      debugPrint('[STORAGE] Secure delete failed for $key: $error');
    }
    _memoryFallback.remove(key);
    _deletedKeys.add(key);
  }
}
