import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/localization/localization_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_provider.dart';
import '../../core/network/interceptors/auth_interceptor.dart';
import '../../core/network/interceptors/error_interceptor.dart';
import '../../core/network/interceptors/language_interceptor.dart';
import '../../core/network/interceptors/mock_interceptor.dart';
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
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/community/presentation/controllers/community_controller.dart';
import '../../features/community/presentation/controllers/story_controller.dart';
import 'package:flutter/painting.dart';
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
    dio.interceptors.addAll([
      LanguageInterceptor(localization),
      MockInterceptor(secureStorage),
    ]);
    final apiClient = ApiClient(dio);
    Get
      ..put<Dio>(dio, permanent: true)
      ..put<ApiClient>(apiClient, permanent: true);

    void handleSessionCleared() {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      mainController.reset();
      if (Get.isRegistered<ProfileController>()) {
        final profileCtrl = Get.find<ProfileController>();
        profileCtrl.profile.value = null;
        profileCtrl.publicProfile.value = null;
        profileCtrl.interests.clear();
        profileCtrl.portfolio.clear();
        profileCtrl.socialLinks.clear();
        profileCtrl.badges.clear();
        profileCtrl.savedItems.clear();
        Get.delete<ProfileController>(force: true);
      }
      if (Get.isRegistered<CommunityController>()) {
        final commCtrl = Get.find<CommunityController>();
        commCtrl.posts.clear();
        commCtrl.activeComments.clear();
        Get.delete<CommunityController>(force: true);
      }
      if (Get.isRegistered<StoryController>()) {
        final storyCtrl = Get.find<StoryController>();
        storyCtrl.storyGroups.clear();
        Get.delete<StoryController>(force: true);
      }
      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>(force: true);
      }
      if (Get.isRegistered<NotificationController>()) {
        Get.delete<NotificationController>(force: true);
      }
    }

    AuthBinding(onSessionCleared: handleSessionCleared).dependencies();

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
