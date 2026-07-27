import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../storage/local_storage.dart';

/// Resolves and persists the active language.
///
/// Resolution order:
/// 1. an **explicit choice** the user made (language select screen or
///    settings) — persisted, always wins;
/// 2. otherwise the **device language**: a Khmer device gets Khmer, any
///    other device gets English. While no explicit choice exists the app
///    keeps following the device — change the phone's language and the app
///    changes with it, live. The account's `preferredLanguage` is applied
///    at sign-in via [syncFromAccount], which updates the UI without
///    ending device-following.
///
/// Three things stay in sync whenever the language changes:
/// * the GetX [Locale] that drives translated UI labels,
/// * the `Accept-Language` header the backend uses to localize system
///   content (lessons, tips, badges, interests),
/// * the user's `preferredLanguage` on their profile.
///
/// The backend `Language` enum is the wire format (ENGLISH / KHMER); the
/// locale code (`en` / `km`) is the Flutter format.
class LocalizationService extends GetxController with WidgetsBindingObserver {
  LocalizationService({required LocalStorage localStorage})
      : _storage = localStorage;

  final LocalStorage _storage;

  static const english = 'ENGLISH';
  static const khmer = 'KHMER';

  static const englishLocale = Locale('en', 'US');
  static const khmerLocale = Locale('km', 'KH');

  static const supportedLocales = <Locale>[englishLocale, khmerLocale];

  /// Fallback when a translation key is missing — English, the app default.
  static const fallbackLocale = englishLocale;

  final language = english.obs;

  /// True once the user (or their account) has picked a language; from then
  /// on the device language is ignored.
  bool _explicitChoice = false;

  Locale get locale => localeOf(language.value);

  /// Value for the `Accept-Language` request header.
  String get headerValue => language.value == khmer ? 'km' : 'en';

  String get languageCode => headerValue;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // Registered so didChangeLocales fires when the device language
    // changes while the app is running ("change together").
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Resolve the starting language. Call before the first frame.
  Future<void> load() async {
    String? stored;
    try {
      stored = await _storage.readLanguage();
    } catch (_) {
      // A failing keystore read must not block startup; fall through to
      // the device language.
    }

    if (stored != null) {
      _explicitChoice = true;
      language.value = stored == khmer ? khmer : english;
    } else {
      language.value = _deviceLanguage();
    }
  }

  /// Follow live device-language changes until the user chooses.
  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_explicitChoice) return;
    language.value = _deviceLanguage(locales?.firstOrNull);
    _applyLocale();
  }

  /// Push the current language into GetX so translated labels actually change.
  ///
  /// This is the one call that re-translates the running UI. `.tr` resolves
  /// against `Get.locale`, and `GetMaterialApp` reads `Get.locale ?? locale`
  /// — so once the app is live, rebuilding with a new `locale:` value does
  /// nothing; only `Get.updateLocale` updates `Get.locale` and forces the
  /// rebuild. Guarded because it throws before a `GetMaterialApp` is mounted
  /// (the startup gap and unit tests); there the initial `locale:` on
  /// [GenLinkKhApp] covers the first paint.
  void _applyLocale() {
    if (Get.key.currentState != null) {
      Get.updateLocale(locale);
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  /// Apply a backend `Language` enum value (ENGLISH / KHMER).
  ///
  /// This is an explicit choice: it persists and stops device-following.
  Future<void> setLanguage(String backendLanguage) async {
    final normalized = backendLanguage == khmer ? khmer : english;
    _explicitChoice = true;
    language.value = normalized;
    _applyLocale();
    await _storage.saveLanguage(normalized);
  }

  /// Adopt the account's `preferredLanguage` after sign-in or a settings
  /// fetch — updates the UI without recording an explicit choice, so a
  /// user who never picked a language keeps following their device.
  void syncFromAccount(String backendLanguage) {
    language.value = backendLanguage == khmer ? khmer : english;
    _applyLocale();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// KHMER for a Khmer-language device, ENGLISH for everything else.
  static String _deviceLanguage([Locale? deviceLocale]) {
    final locale = deviceLocale ?? PlatformDispatcher.instance.locale;
    return locale.languageCode.toLowerCase() == 'km' ? khmer : english;
  }

  static Locale localeOf(String backendLanguage) =>
      backendLanguage == khmer ? khmerLocale : englishLocale;
}
