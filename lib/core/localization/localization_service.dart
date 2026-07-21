import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../storage/local_storage.dart';

/// Resolves and persists the active language.
///
/// Three things stay in sync:
/// * the GetX [Locale] that drives translated UI labels,
/// * the `Accept-Language` header the backend uses to localize system
///   content (lessons, tips, badges, interests),
/// * the user's `preferredLanguage` on their profile.
///
/// The backend `Language` enum is the wire format (ENGLISH / KHMER); the
/// locale code (`en` / `km`) is the Flutter format.
class LocalizationService extends GetxController {
  LocalizationService({required LocalStorage localStorage})
      : _storage = localStorage;

  final LocalStorage _storage;

  static const english = 'ENGLISH';
  static const khmer = 'KHMER';

  static const englishLocale = Locale('en', 'US');
  static const khmerLocale = Locale('km', 'KH');

  static const supportedLocales = <Locale>[englishLocale, khmerLocale];

  /// GenLink KH is Khmer-first, matching the backend default.
  static const fallbackLocale = khmerLocale;

  final language = khmer.obs;

  Locale get locale => localeOf(language.value);

  /// Value for the `Accept-Language` request header.
  String get headerValue => language.value == khmer ? 'km' : 'en';

  String get languageCode => headerValue;

  /// Load the persisted preference. Call before the first frame.
  Future<void> load() async {
    final stored = await _storage.readLanguage();
    if (stored != null) {
      language.value = stored == khmer ? khmer : english;
    }
  }

  /// Apply a backend `Language` enum value (ENGLISH / KHMER).
  Future<void> setLanguage(String backendLanguage) async {
    final normalized = backendLanguage == khmer ? khmer : english;
    if (language.value == normalized) return;
    language.value = normalized;
    await _storage.saveLanguage(normalized);
    Get.updateLocale(localeOf(normalized));
  }

  static Locale localeOf(String backendLanguage) =>
      backendLanguage == khmer ? khmerLocale : englishLocale;
}
