import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/app_realtime_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/quiz_match_realtime_data_source.dart';
import '../../data/datasources/quiz_remote_data_source.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../controllers/quiz_controller.dart';
import '../controllers/quiz_match_controller.dart';

class QuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuizRemoteDataSource>(
      () => QuizRemoteDataSourceImpl(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<QuizRepository>(
      () => QuizRepositoryImpl(Get.find<QuizRemoteDataSource>()),
      fenix: true,
    );
    Get.lazyPut<QuizMatchRealtimeDataSource>(
      () => QuizMatchRealtimeDataSourceImpl(Get.find<AppRealtimeService>()),
      fenix: true,
    );
    Get.lazyPut(() => QuizController(), fenix: true);
    Get.lazyPut(
      () => QuizMatchController(
        quizRepository: Get.find<QuizRepository>(),
        realtimeDataSource: Get.find<QuizMatchRealtimeDataSource>(),
        authController: Get.find<AuthController>(),
      ),
      fenix: true,
    );
  }
}
