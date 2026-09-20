import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/short_content_remote_data_source.dart';
import '../../data/repositories/short_content_repository_impl.dart';
import '../../domain/repositories/short_content_repository.dart';
import '../controllers/short_content_controller.dart';

class ShortContentBinding extends Bindings {
  @override
  void dependencies() {
    registerRepositories();
    Get.lazyPut<ShortContentController>(
      () => ShortContentController(
        repository: Get.find<ShortContentRepository>(),
      ),
      fenix: true,
    );
  }

  static void registerRepositories() {
    Get.lazyPut<ShortContentRemoteDataSource>(
      () => ShortContentRemoteDataSourceImpl(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<ShortContentRepository>(
      () =>
          ShortContentRepositoryImpl(Get.find<ShortContentRemoteDataSource>()),
      fenix: true,
    );
  }
}

class ShortContentDetailBinding extends Bindings {
  static const tag = 'short-content-detail';

  @override
  void dependencies() {
    ShortContentBinding.registerRepositories();
    Get.lazyPut<ShortContentController>(
      () => ShortContentController(
        repository: Get.find<ShortContentRepository>(),
        autoLoadFeed: false,
      ),
      tag: tag,
    );
  }
}
