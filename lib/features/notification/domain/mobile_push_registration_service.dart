/// Registers the current mobile installation with the authenticated account.
///
/// Authentication owns when a session starts or ends; the implementation owns
/// Firebase Messaging and the device-registration API details.
abstract interface class MobilePushRegistrationService {
  Future<void> registerCurrentDevice();

  /// Deactivates the current device remotely when [remote] is true. When a
  /// session has expired, callers can clear local state without making another
  /// request with an expired access token.
  Future<void> deactivateCurrentDevice({bool remote = true});
}
