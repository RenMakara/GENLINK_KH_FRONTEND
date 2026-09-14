import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genlink_frontend/app/bindings/initial_binding.dart';
import 'package:genlink_frontend/core/localization/localization_service.dart';
import 'package:genlink_frontend/core/network/api_client.dart';
import 'package:genlink_frontend/core/storage/local_storage.dart';
import 'package:genlink_frontend/core/storage/secure_storage.dart';
import 'package:genlink_frontend/core/theme/theme_controller.dart';
import 'package:genlink_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:genlink_frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:genlink_frontend/features/media/domain/media_upload_service.dart';
import 'package:genlink_frontend/features/media/presentation/media_picker.dart';
import 'package:genlink_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:genlink_frontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:genlink_frontend/features/settings/presentation/bindings/settings_binding.dart';
import 'package:genlink_frontend/features/settings/presentation/controllers/settings_controller.dart';
import 'package:genlink_frontend/main_controller.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => InitialBinding().dependencies());
  tearDown(Get.reset);

  test('composition root registers global and shared dependencies', () {
    expect(Get.isRegistered<SecureStorage>(), isTrue);
    expect(Get.isRegistered<LocalStorage>(), isTrue);
    expect(Get.isRegistered<LocalizationService>(), isTrue);
    expect(Get.isRegistered<ThemeController>(), isTrue);
    expect(Get.isRegistered<MainController>(), isTrue);
    expect(Get.isRegistered<Dio>(), isTrue);
    expect(Get.isRegistered<ApiClient>(), isTrue);
    expect(Get.isRegistered<MediaUploadService>(), isTrue);
    expect(Get.isRegistered<MediaPicker>(), isTrue);
    expect(Get.isRegistered<AuthRepository>(), isTrue);
    expect(Get.isRegistered<AuthController>(), isTrue);
  });

  test('Settings binding owns a repository independent from Profile', () {
    expect(Get.isRegistered<SettingsRepository>(), isFalse);
    expect(Get.isRegistered<ProfileRepository>(), isFalse);

    SettingsBinding().dependencies();

    expect(Get.isRegistered<SettingsRepository>(), isTrue);
    expect(Get.isRegistered<SettingsController>(), isTrue);
    expect(Get.isRegistered<ProfileRepository>(), isFalse);
  });
}
