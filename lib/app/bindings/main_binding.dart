import 'package:get/get.dart';

import '../../features/community/presentation/bindings/community_binding.dart';
import '../../features/finance/presentation/bindings/finance_binding.dart';
import '../../features/home/presentation/bindings/home_binding.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';

/// Composes dependencies for the signed-in tab shell.
class MainBinding extends Bindings {
  @override
  void dependencies() {
    HomeBinding().dependencies();
    CommunityBinding().dependencies();
    FinanceBinding().dependencies();
    ProfileBinding().dependencies();
  }
}
