import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../storage/local_storage.dart';

class LocalizationService extends GetxController with WidgetsBindingObserver {
  LocalizationService({required LocalStorage localStorage})
      : _storage = localStorage;

  final LocalStorage _storage;

  static const english = 'ENGLISH';
  static const khmer = 'KHMER';

  static const englishLocale = Locale('en', 'US');
  static const khmerLocale = Locale('km', 'KH');

  static const supportedLocales = <Locale>[englishLocale, khmerLocale];

  static const fallbackLocale = englishLocale;

  final language = english.obs;

  bool _explicitChoice = false;

  Locale get locale => localeOf(language.value);

  String get headerValue => language.value == khmer ? 'km' : 'en';

  String get languageCode => headerValue;


  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> load() async {
    String? stored;
    try {
      stored = await _storage.readLanguage();
    } catch (_) {
    }

    if (stored != null) {
      _explicitChoice = true;
      language.value = stored == khmer ? khmer : english;
    } else {
      language.value = _deviceLanguage();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_explicitChoice) return;
    language.value = _deviceLanguage(locales?.firstOrNull);
    _applyLocale();
  }

  void _applyLocale() {
    if (Get.key.currentState != null) {
      Get.updateLocale(locale);
    }
  }


  Future<void> setLanguage(String backendLanguage) async {
    final normalized = backendLanguage == khmer ? khmer : english;
    _explicitChoice = true;
    language.value = normalized;
    _applyLocale();
    await _storage.saveLanguage(normalized);
  }

  void syncFromAccount(String backendLanguage) {
    final target = backendLanguage == khmer ? khmer : english;
    if (language.value == target) return;

    language.value = target;
    _applyLocale();
  }


  static String _deviceLanguage([Locale? deviceLocale]) {
    final locale = deviceLocale ?? PlatformDispatcher.instance.locale;
    return locale.languageCode.toLowerCase() == 'km' ? khmer : english;
  }

  static Locale localeOf(String backendLanguage) =>
      backendLanguage == khmer ? khmerLocale : englishLocale;
}
