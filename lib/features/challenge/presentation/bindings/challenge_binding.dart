import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/challenge_remote_data_source.dart';
import '../../data/repositories/challenge_repository_impl.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../controllers/challenge_controller.dart';

class ChallengeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChallengeRemoteDataSource>(
      () => ChallengeRemoteDataSourceImpl(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<ChallengeRepository>(
      () => ChallengeRepositoryImpl(Get.find<ChallengeRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut(
      () => ChallengeController(
        repository: Get.find<ChallengeRepository>(),
        authController: Get.find<AuthController>(),
      ),
      fenix: true,
    );
  }
}
