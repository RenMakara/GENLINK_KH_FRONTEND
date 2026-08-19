import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/quiz_remote_data_source.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../controllers/quiz_controller.dart';

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
    Get.lazyPut(() => QuizController(), fenix: true);
  }
}
