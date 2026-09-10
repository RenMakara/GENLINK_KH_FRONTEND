import 'package:get/get.dart';

import '../../features/chat/presentation/bindings/chat_binding.dart';
import '../../features/community/presentation/bindings/community_binding.dart';
import '../../features/finance/presentation/bindings/finance_binding.dart';
import '../../features/home/presentation/bindings/home_binding.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';

/// Composes dependencies for the signed-in tab shell.
class MainBinding extends Bindings {
  @override
  void dependencies() {
    // The legacy Home data module supplies the LevelUp tab's progress and
    // productivity state. Community is the first tab in MainScreen.
    HomeBinding().dependencies();
    CommunityBinding().dependencies();
    FinanceBinding().dependencies();
    ProfileBinding().dependencies();
    ChatBinding().dependencies();
  }
}
