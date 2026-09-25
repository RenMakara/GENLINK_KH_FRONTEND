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
    required this.apiClient,
    this.messaging,
  });

  final ApiClient apiClient;
  final FirebaseMessaging? messaging;

  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void>? _registrationInFlight;
  String? _registeredDeviceId;
  String? _registeredToken;
  bool _sessionActive = false;
  int _sessionGeneration = 0;

  @override
  Future<void> registerCurrentDevice() {
    final inFlight = _registrationInFlight;
    if (inFlight != null) return inFlight;

    final generation = ++_sessionGeneration;
    _sessionActive = true;
    final registration = _registerCurrentDevice(generation);
    late final Future<void> trackedRegistration;
    trackedRegistration = registration.whenComplete(() {
      if (identical(_registrationInFlight, trackedRegistration)) {
        _registrationInFlight = null;
      }
    });
    _registrationInFlight = trackedRegistration;
    return trackedRegistration;
  }

  Future<void> _registerCurrentDevice(int generation) async {
    final platform = _platformName;
    if (platform == null) return;

    if (Firebase.apps.isEmpty) {
      debugPrint(
        '[FCM] Firebase is not initialized; device registration skipped.',
      );
      return;
    }

    final messaging = this.messaging ?? FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!_isCurrentSession(generation)) return;

    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint(
        '[FCM] Notification permission denied; device registration skipped.',
      );
      return;
    }

    final token = (await messaging.getToken())?.trim();
    if (token == null || token.isEmpty || !_isCurrentSession(generation)) {
      debugPrint('[FCM] No registration token is available yet.');
      return;
    }

    await _registerToken(platform, token, generation);
    if (!_isCurrentSession(generation)) return;

    _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen((nextToken) {
      if (_isCurrentSession(generation)) {
        unawaited(_registerRefreshedToken(platform, nextToken, generation));
      }
    });
  }

  Future<void> _registerRefreshedToken(
    String platform,
    String token,
    int generation,
  ) async {
    try {
      final normalized = token.trim();
      if (normalized.isEmpty || !_isCurrentSession(generation)) return;
      await _registerToken(platform, normalized, generation);
    } catch (error, stackTrace) {
      debugPrint(
        '[FCM] Token refresh registration failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> _registerToken(
    String platform,
    String token,
    int generation,
  ) async {
    if (!_isCurrentSession(generation)) return;

    final previousDeviceId = _registeredDeviceId;
    if (previousDeviceId != null &&
        _registeredToken != null &&
        _registeredToken != token) {
      await _deactivateRemotely(previousDeviceId);
      if (!_isCurrentSession(generation)) return;
    }

    final response = await apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.notificationDevices,
      body: <String, dynamic>{'platform': platform, 'token': token},
      parse: ApiClient.asMap,
    );
    final deviceId = response['deviceId']?.toString();

    // Logout can race with the token request. Remove a row that was created
    // after logout instead of leaving it associated with the old account.
    if (!_isCurrentSession(generation)) {
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
  Future<void> deactivateCurrentDevice({
    bool remote = true,
    bool waitForRegistration = true,
  }) async {
    _sessionActive = false;
    _sessionGeneration++;
    final subscription = _tokenRefreshSubscription;
    _tokenRefreshSubscription = null;
    await subscription?.cancel();

    final registration = _registrationInFlight;
    if (waitForRegistration && registration != null) {
      try {
        await registration;
      } catch (error, stackTrace) {
        // Registration is supplemental. A failed in-flight request must not
        // block logout or local session cleanup.
        debugPrint('[FCM] In-flight registration stopped: $error\n$stackTrace');
      }
    }

    final deviceId = _registeredDeviceId;
    _registeredDeviceId = null;
    _registeredToken = null;
    if (remote && deviceId != null && deviceId.isNotEmpty) {
      await _deactivateRemotely(deviceId);
    }
  }

  Future<void> _deactivateRemotely(String deviceId) async {
    try {
      await apiClient.delete(ApiEndpoints.notificationDevice(deviceId));
    } catch (error, stackTrace) {
      // The next login re-registers the token and re-associates it with the
      // new account even if logout happened while the API was unavailable.
      debugPrint('[FCM] Device deactivation failed: $error\n$stackTrace');
    }
  }

  bool _isCurrentSession(int generation) =>
      _sessionActive && generation == _sessionGeneration;

  String? get _platformName {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'ANDROID',
      TargetPlatform.iOS => 'IOS',
      _ => null,
    };
  }
}
