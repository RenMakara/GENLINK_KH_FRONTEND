import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Language resolution: default English; a Khmer device auto-selects Khmer;
/// device changes are followed until the user makes an explicit choice; an
/// account sync never ends device-following.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSecureStorage storage;
  late LocalizationService service;

  setUp(() {
    storage = _MockSecureStorage();
    when(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    service = LocalizationService(
      localStorage: LocalStorage(storage: storage),
    );
  });

  void stubStored(String? value) =>
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => value);

  test('defaults to English on a non-Khmer device with nothing stored',
      () async {
    stubStored(null);
    await service.load();
    // The test environment's platform locale is en_US.
    expect(PlatformDispatcher.instance.locale.languageCode, 'en');
    expect(service.language.value, LocalizationService.english);
  });

  test('a stored explicit choice wins over the device language', () async {
    stubStored(LocalizationService.khmer);
    await service.load();
    expect(service.language.value, LocalizationService.khmer);
  });

  test('a broken storage read falls back to the device language', () async {
    when(() => storage.read(key: any(named: 'key')))
        .thenThrow(Exception('keystore reset'));
    await service.load();
    expect(service.language.value, LocalizationService.english);
  });

  test('follows a device change to Khmer while no explicit choice exists',
      () async {
    stubStored(null);
    await service.load();

    service.didChangeLocales(const [Locale('km', 'KH')]);

    expect(service.language.value, LocalizationService.khmer,
        reason: 'no explicit choice yet — the app changes together with '
            'the device');
  });

  test('stops following the device after an explicit choice', () async {
    stubStored(null);
    await service.load();

    await service.setLanguage(LocalizationService.english);
    service.didChangeLocales(const [Locale('km', 'KH')]);

    expect(service.language.value, LocalizationService.english,
        reason: 'the user picked English; the device no longer decides');
  });

  test('an account sync does not end device-following', () async {
    stubStored(null);
    await service.load();

    service.syncFromAccount(LocalizationService.english);
    service.didChangeLocales(const [Locale('km', 'KH')]);

    expect(service.language.value, LocalizationService.khmer,
        reason: 'sign-in adopted the account value, but the user never '
            'chose — device changes still apply');
  });
}
