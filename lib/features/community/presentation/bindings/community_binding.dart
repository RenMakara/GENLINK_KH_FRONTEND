import 'package:get/get.dart';
import '../../data/repositories/story_repository_impl.dart';
import '../../domain/repositories/story_repository.dart';
import '../controllers/community_controller.dart';
import '../controllers/story_controller.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoryRepository>(() => StoryRepositoryImpl());
    Get.lazyPut<CommunityController>(() => CommunityController());
    Get.lazyPut<StoryController>(() => StoryController());
  }
}
