import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/localization/localization_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/app_realtime_service.dart';
import '../../core/network/dio_provider.dart';
import '../../core/network/interceptors/auth_interceptor.dart';
import '../../core/network/interceptors/error_interceptor.dart';
import '../../core/network/interceptors/language_interceptor.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/theme_controller.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/media/data/datasources/media_remote_datasource.dart';
import '../../features/media/data/repositories/media_repository_impl.dart';
import '../../features/media/domain/media_upload_service.dart';
import '../../features/media/presentation/media_picker.dart';
import '../../features/notification/data/firebase_mobile_notification_service.dart';
import '../../features/notification/data/firebase_mobile_push_registration_service.dart';
import '../../features/notification/domain/mobile_push_registration_service.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/productivity/presentation/controllers/productivity_controller.dart';
import '../../features/community/presentation/controllers/community_controller.dart';
import '../../features/community/presentation/controllers/story_controller.dart';
import 'package:flutter/painting.dart';
import '../../features/notification/presentation/bindings/notification_binding.dart';
import '../../features/chat/presentation/controllers/chat_controller.dart';
import '../../features/notification/presentation/controllers/notification_controller.dart';
import '../../main_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final secureStorage = SecureStorage();
    final localStorage = LocalStorage();
    final localization = LocalizationService(localStorage: localStorage);
    final mainController = MainController();

    Get
      ..put<SecureStorage>(secureStorage, permanent: true)
      ..put<LocalStorage>(localStorage, permanent: true)
      ..put<LocalizationService>(localization, permanent: true)
      ..put<ThemeController>(
        ThemeController(localStorage: localStorage),
        permanent: true,
      )
      ..put<MainController>(mainController, permanent: true);

    final dio = DioProvider.create();
    dio.interceptors.addAll([LanguageInterceptor(localization)]);
    final apiClient = ApiClient(dio);
    Get
      ..put<Dio>(dio, permanent: true)
      ..put<ApiClient>(apiClient, permanent: true);

    ProfileBinding.registerOwnerController();

    NotificationBinding().dependencies();

    final mobilePushRegistrationService = FirebaseMobilePushRegistrationService(
      apiClient: apiClient,
    );
    final mobileNotificationService = FirebaseMobileNotificationService();
    Get.put<MobilePushRegistrationService>(
      mobilePushRegistrationService,
      permanent: true,
    );
    Get.put<FirebaseMobileNotificationService>(
      mobileNotificationService,
      permanent: true,
    );

    final realtimeService = AppRealtimeService(secureStorage: secureStorage);
    Get.put<AppRealtimeService>(realtimeService, permanent: true);

    void handleSessionCleared() {
      if (Get.isRegistered<AppRealtimeService>()) {
        Get.find<AppRealtimeService>().disconnect();
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      mainController.reset();
      Get.delete<ProfileController>(force: true);
      ProfileBinding.registerOwnerController();
      Get.delete<CommunityController>(force: true);
      Get.delete<StoryController>(force: true);
      Get.delete<ChatController>(force: true);
      Get.delete<NotificationController>(force: true);
      Get.delete<ProductivityController>(force: true);
    }

    AuthBinding(
      onSessionCleared: handleSessionCleared,
      onSessionEstablished: () {
        // The app may have started without a token, so the bootstrap-time
        // realtime connection can have been skipped. Reconnect only after
        // auth has persisted a valid session.
        unawaited(realtimeService.connect());
      },
      mobilePushRegistrationService: mobilePushRegistrationService,
    ).dependencies();

    final authInterceptor = AuthInterceptor(
      secureStorage: secureStorage,
      authRepository: Get.find<AuthRepository>(),
      onSessionExpired: () async {
        if (Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().onSessionExpired();
        } else {
          await secureStorage.clearAll();
          handleSessionCleared();
        }
      },
    )..client = dio;

    dio.interceptors.addAll([authInterceptor, ErrorInterceptor()]);

    Get
      ..put<MediaUploadService>(
        MediaUploadService(
          MediaRepositoryImpl(MediaRemoteDatasource(apiClient)),
        ),
        permanent: true,
      )
      ..put<MediaPicker>(MediaPicker(), permanent: true);
  }
}
