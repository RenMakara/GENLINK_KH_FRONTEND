import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/mobile_push_registration_service.dart';

/// Bridges Firebase Messaging to the authenticated device-registration API.
///
/// FCM tokens are never written to application logs. The backend stores the
/// token encrypted and returns only safe device metadata.
class FirebaseMobilePushRegistrationService
    implements MobilePushRegistrationService {
  FirebaseMobilePushRegistrationService({
    required ApiClient apiClient,
    FirebaseMessaging? messaging,
  }) : _apiClient = apiClient,
       _messaging = messaging;

  final ApiClient _apiClient;
  final FirebaseMessaging? _messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void>? _registrationInFlight;
  String? _registeredDeviceId;
  String? _registeredToken;
  bool _sessionActive = false;

  @override
  Future<void> registerCurrentDevice() =>
      _registrationInFlight ??= _registerCurrentDevice().whenComplete(() {
        _registrationInFlight = null;
      });

  Future<void> _registerCurrentDevice() async {
    final platform = _platformName;
    if (platform == null) return;

    _sessionActive = true;
    if (Firebase.apps.isEmpty) {
      debugPrint(
        '[FCM] Firebase is not initialized; device registration skipped.',
      );
      return;
    }

    final messaging = _messaging ?? FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!_sessionActive) return;

    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint(
        '[FCM] Notification permission denied; device registration skipped.',
      );
      return;
    }

    final token = (await messaging.getToken())?.trim();
    if (token == null || token.isEmpty || !_sessionActive) {
      debugPrint('[FCM] No registration token is available yet.');
      return;
    }

    await _registerToken(platform, token);
    if (!_sessionActive) return;

    _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen((nextToken) {
      if (_sessionActive) {
        unawaited(_registerRefreshedToken(platform, nextToken));
      }
    });
  }

  Future<void> _registerRefreshedToken(String platform, String token) async {
    try {
      final normalized = token.trim();
      if (normalized.isEmpty || !_sessionActive) return;
      await _registerToken(platform, normalized);
    } catch (error, stackTrace) {
      debugPrint(
        '[FCM] Token refresh registration failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _registerToken(String platform, String token) async {
    if (!_sessionActive) return;

    final previousDeviceId = _registeredDeviceId;
    if (previousDeviceId != null &&
        _registeredToken != null &&
        _registeredToken != token) {
      await _deactivateRemotely(previousDeviceId);
      if (!_sessionActive) return;
    }

    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.notificationDevices,
      body: <String, dynamic>{'platform': platform, 'token': token},
      parse: ApiClient.asMap,
    );
    final deviceId = response['deviceId']?.toString();

    // Logout can race with the token request. Remove a row that was created
    // after logout instead of leaving it associated with the old account.
    if (!_sessionActive) {
      if (deviceId != null && deviceId.isNotEmpty) {
        await _deactivateRemotely(deviceId);
      }
      return;
    }

    _registeredDeviceId = deviceId;
    _registeredToken = token;
    debugPrint(
      '[FCM] Device registered platform=$platform tokenLength=${token.length}',
    );
  }

  @override
  Future<void> deactivateCurrentDevice({bool remote = true}) async {
    _sessionActive = false;
    final subscription = _tokenRefreshSubscription;
    _tokenRefreshSubscription = null;
    await subscription?.cancel();

    final deviceId = _registeredDeviceId;
    _registeredDeviceId = null;
    _registeredToken = null;
    if (remote && deviceId != null && deviceId.isNotEmpty) {
      await _deactivateRemotely(deviceId);
    }
  }

  Future<void> _deactivateRemotely(String deviceId) async {
    try {
      await _apiClient.delete(ApiEndpoints.notificationDevice(deviceId));
    } catch (error, stackTrace) {
      // The next login re-registers the token and re-associates it with the
      // new account even if logout happened while the API was unavailable.
      debugPrint('[FCM] Device deactivation failed: $error\n$stackTrace');
    }
  }

  String? get _platformName {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'ANDROID',
      TargetPlatform.iOS => 'IOS',
      _ => null,
    };
  }
}
