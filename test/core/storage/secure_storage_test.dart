import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';

void main() {
  late _InMemorySecureStorage storage;

  setUp(() {
    storage = _InMemorySecureStorage();
  });

  group('SecureStorage', () {
    test('save and read access token', () async {
      await storage.saveAccessToken('test-access-token');
      final token = await storage.readAccessToken();
      expect(token, 'test-access-token');
    });

    test('save and read refresh token', () async {
      await storage.saveRefreshToken('test-refresh-token');
      final token = await storage.readRefreshToken();
      expect(token, 'test-refresh-token');
    });

    test('save and read token expiry', () async {
      final now = DateTime.now();
      await storage.saveTokenExpiry(now);
      final expiry = await storage.readTokenExpiry();
      expect(expiry, isNotNull);
      expect(expiry!.year, now.year);
      expect(expiry.month, now.month);
      expect(expiry.day, now.day);
    });

    test('save and read user email', () async {
      await storage.saveUserEmail('user@example.com');
      final email = await storage.readUserEmail();
      expect(email, 'user@example.com');
    });

    test('save and read user id', () async {
      await storage.saveUserId('uuid-123');
      final id = await storage.readUserId();
      expect(id, 'uuid-123');
    });

    test('saveTokenPair stores both tokens and expiry', () async {
      await storage.saveTokenPair(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      );
      final access = await storage.readAccessToken();
      final refresh = await storage.readRefreshToken();
      final expiry = await storage.readTokenExpiry();

      expect(access, 'access-123');
      expect(refresh, 'refresh-456');
      expect(expiry, isNotNull);
    });

    test('clearAll removes all stored data', () async {
      await storage.saveAccessToken('access');
      await storage.saveRefreshToken('refresh');
      await storage.saveUserEmail('email');
      await storage.saveUserId('id');

      await storage.clearAll();

      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(await storage.readUserEmail(), isNull);
      expect(await storage.readUserId(), isNull);
    });

    test('reading nonexistent key returns null', () async {
      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(await storage.readTokenExpiry(), isNull);
      expect(await storage.readUserEmail(), isNull);
      expect(await storage.readUserId(), isNull);
    });
  });
}

class _InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> saveAccessToken(String token) async =>
      _store['genlink_access_token'] = token;

  @override
  Future<String?> readAccessToken() async =>
      _store['genlink_access_token'];

  @override
  Future<void> saveRefreshToken(String token) async =>
      _store['genlink_refresh_token'] = token;

  @override
  Future<String?> readRefreshToken() async =>
      _store['genlink_refresh_token'];

  @override
  Future<void> saveTokenExpiry(DateTime expiry) async =>
      _store['genlink_token_expiry'] = expiry.toIso8601String();

  @override
  Future<DateTime?> readTokenExpiry() async {
    final raw = _store['genlink_token_expiry'];
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  @override
  Future<void> saveUserEmail(String email) async =>
      _store['genlink_user_email'] = email;

  @override
  Future<String?> readUserEmail() async =>
      _store['genlink_user_email'];

  @override
  Future<void> saveUserId(String id) async =>
      _store['genlink_user_id'] = id;

  @override
  Future<String?> readUserId() async =>
      _store['genlink_user_id'];

  @override
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

  @override
  Future<void> clearAll() async => _store.clear();
}
