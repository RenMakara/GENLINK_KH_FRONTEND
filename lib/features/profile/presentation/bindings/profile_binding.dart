import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_setup_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    _registerRepository();

    final publicUsername = Get.parameters['username']?.trim();
    if (publicUsername != null && publicUsername.isNotEmpty) {
      Get.lazyPut<ProfileController>(
        () => ProfileController(
          repository: Get.find<ProfileRepository>(),
          viewingUsername: publicUsername,
        ),
        tag: ProfileController.publicTag(publicUsername),
      );
      return;
    }

    Get.lazyPut<ProfileController>(
      () => ProfileController(
        repository: Get.find<ProfileRepository>(),
        onOwnerProfileChanged: syncCachedAuthUser,
      ),
      fenix: true,
    );
  }

  static void syncCachedAuthUser(ProfileEntity profile) {
    if (!Get.isRegistered<AuthController>()) return;
    final auth = Get.find<AuthController>();
    final cached = auth.currentUser.value;

    auth.updateCachedUser(
      UserEntity(
        id: profile.userId,
        fullName: profile.fullName,
        username: profile.username,
        email: profile.email,
        phoneNumber: profile.phoneNumber,
        avatarUrl: profile.avatarUrl,
        bio: profile.bio,
        universityName: profile.universityName,
        workStatus: profile.workStatus,
        location: profile.location,
        emailVerified: profile.emailVerified,
        accountStatus: profile.accountStatus,
        totalXp: profile.totalXp,
        level: profile.level,
        preferredLanguage: profile.preferredLanguage,
        role: cached?.role ?? 'USER',
        active: cached?.active ?? true,
      ),
    );
  }

  static void _registerRepository() {
    if (Get.isRegistered<ProfileRepository>()) return;
    Get.put<ProfileRepository>(
      ProfileRepositoryImpl(ProfileRemoteDatasource(Get.find<ApiClient>())),
      permanent: true,
    );
  }
}

class ProfileSetupBinding extends Bindings {
  @override
  void dependencies() {
    ProfileBinding._registerRepository();
    Get.lazyPut<ProfileSetupController>(
      () => ProfileSetupController(repository: Get.find<ProfileRepository>()),
    );
  }
}
