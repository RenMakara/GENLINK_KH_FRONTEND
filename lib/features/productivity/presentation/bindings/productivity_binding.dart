import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/productivity_remote_datasource.dart';
import '../../data/repositories/productivity_repository_impl.dart';
import '../../domain/repositories/productivity_repository.dart';
import '../controllers/productivity_controller.dart';

class ProductivityBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProductivityRepository>()) {
      Get.put<ProductivityRepository>(
        ProductivityRepositoryImpl(
          ProductivityRemoteDatasource(Get.find<ApiClient>()),
        ),
        permanent: true,
      );
    }

    Get.lazyPut<ProductivityController>(
      () => ProductivityController(
        repository: Get.find<ProductivityRepository>(),
      ),
      fenix: true,
    );
  }
}
