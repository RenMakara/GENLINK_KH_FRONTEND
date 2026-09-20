import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  LocalStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kThemeMode = 'genlink_theme_mode';
  static const _kLanguage = 'genlink_language';
  static const _kInitialPreferencesSeen = 'genlink_initial_preferences_seen';
  static const _kOnboardingSeen = 'genlink_onboarding_seen';


  Future<String?> readThemeMode() => _storage.read(key: _kThemeMode);

  Future<void> saveThemeMode(String theme) =>
      _storage.write(key: _kThemeMode, value: theme);


  Future<String?> readLanguage() => _storage.read(key: _kLanguage);

  Future<void> saveLanguage(String language) =>
      _storage.write(key: _kLanguage, value: language);


  Future<bool> readInitialPreferencesSeen() async {
    final stored = await _storage.read(key: _kInitialPreferencesSeen);
    if (stored == 'true') return true;
    return readOnboardingSeen();
  }

  Future<void> markInitialPreferencesSeen() =>
      _storage.write(key: _kInitialPreferencesSeen, value: 'true');

  Future<bool> readOnboardingSeen() async =>
      await _storage.read(key: _kOnboardingSeen) == 'true';

  Future<void> markOnboardingSeen() =>
      _storage.write(key: _kOnboardingSeen, value: 'true');


  static const _kStoryDraft = 'genlink_story_draft';
  static const _kRecentSearchesPrefix = 'genlink_recent_searches_';

  Future<String?> readRecentSearches(String userId) =>
      _storage.read(key: '$_kRecentSearchesPrefix$userId');

  Future<void> saveRecentSearches(String userId, String jsonList) =>
      _storage.write(key: '$_kRecentSearchesPrefix$userId', value: jsonList);

  Future<void> clearRecentSearches(String userId) =>
      _storage.delete(key: '$_kRecentSearchesPrefix$userId');

  Future<String?> readStoryDraft() => _storage.read(key: _kStoryDraft);

  Future<void> saveStoryDraft(String draftData) =>
      _storage.write(key: _kStoryDraft, value: draftData);

  Future<void> deleteStoryDraft() => _storage.delete(key: _kStoryDraft);

  Future<void> clearAll() async {
    await _storage.delete(key: _kThemeMode);
    await _storage.delete(key: _kLanguage);
    await _storage.delete(key: _kInitialPreferencesSeen);
    await _storage.delete(key: _kOnboardingSeen);
    await _storage.delete(key: _kStoryDraft);
  }
}
