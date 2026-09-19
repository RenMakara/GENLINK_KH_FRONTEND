import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/leaderboard_remote_data_source.dart';
import '../../data/repositories/leaderboard_repository_impl.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../controllers/leaderboard_controller.dart';

class LeaderboardBinding extends Bindings {
  static void registerDataDependencies() {
    if (!Get.isRegistered<ApiClient>()) return;
    if (!Get.isRegistered<LeaderboardRemoteDataSource>()) {
      Get.lazyPut<LeaderboardRemoteDataSource>(
        () => LeaderboardRemoteDataSourceImpl(Get.find<ApiClient>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<LeaderboardRepository>()) {
      Get.lazyPut<LeaderboardRepository>(
        () =>
            LeaderboardRepositoryImpl(Get.find<LeaderboardRemoteDataSource>()),
        fenix: true,
      );
    }
  }

  @override
  void dependencies() {
    registerDataDependencies();
    Get.lazyPut(() => LeaderboardController(), fenix: true);
  }
}
