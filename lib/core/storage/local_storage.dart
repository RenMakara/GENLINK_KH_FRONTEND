import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Non-sensitive preferences, cached flags, and lightweight local
/// persistence: theme mode, locale, onboarding state.
///
/// Backed by [FlutterSecureStorage] rather than `shared_preferences`
/// simply because it is the storage dependency the project already has.
/// Nothing written here is a secret; swapping the backing store later
/// only touches this file.
class LocalStorage {
  LocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Keys
  static const _kThemeMode = 'genlink_theme_mode';
  static const _kLanguage = 'genlink_language';
  static const _kOnboardingSeen = 'genlink_onboarding_seen';

  // ── Theme ─────────────────────────────────────────────────────────────

  /// Stored as the backend `Theme` enum: LIGHT / DARK / SYSTEM_DEFAULT.
  Future<String?> readThemeMode() => _storage.read(key: _kThemeMode);

  Future<void> saveThemeMode(String theme) =>
      _storage.write(key: _kThemeMode, value: theme);

  // ── Language ──────────────────────────────────────────────────────────

  /// Stored as the backend `Language` enum: ENGLISH / KHMER.
  Future<String?> readLanguage() => _storage.read(key: _kLanguage);

  Future<void> saveLanguage(String language) =>
      _storage.write(key: _kLanguage, value: language);

  // ── Onboarding ────────────────────────────────────────────────────────

  Future<bool> readOnboardingSeen() async =>
      await _storage.read(key: _kOnboardingSeen) == 'true';

  Future<void> markOnboardingSeen() =>
      _storage.write(key: _kOnboardingSeen, value: 'true');

  // ── Story Draft ────────────────────────────────────────────────────────

  static const _kStoryDraft = 'genlink_story_draft';

  Future<String?> readStoryDraft() => _storage.read(key: _kStoryDraft);

  Future<void> saveStoryDraft(String draftData) =>
      _storage.write(key: _kStoryDraft, value: draftData);

  Future<void> deleteStoryDraft() => _storage.delete(key: _kStoryDraft);

  /// Clear preferences. Not called on logout — theme and language are
  /// device preferences that outlive the session.
  Future<void> clearAll() async {
    await _storage.delete(key: _kThemeMode);
    await _storage.delete(key: _kLanguage);
    await _storage.delete(key: _kOnboardingSeen);
    await _storage.delete(key: _kStoryDraft);
  }
}
