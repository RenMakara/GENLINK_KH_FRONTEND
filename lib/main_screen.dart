import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'features/community/presentation/bindings/community_binding.dart';
import 'features/community/presentation/screens/community_screen.dart';
import 'features/community/presentation/screens/create_post_screen.dart';
import 'features/finance/presentation/screens/Finance Home/screens/finance_screen.dart';
import 'features/home/presentation/bindings/home_binding.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/profile/presentation/bindings/profile_binding.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'main_controller.dart';
import 'shared/widgets/bottom_nav_bar.dart';

/// Signed-in shell. The tab order here must match [BottomNavBar]:
/// Home (0), Community (1), Financial (2), Profile (3).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainController controller;

  late final List<Widget> pages = [
    HomeScreen(onNavigateTab: (index) => controller.changeIndex(index)),
    const CommunityScreen(),
    const FinanceScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<MainController>()
        ? Get.find<MainController>()
        : Get.put(MainController(), permanent: true);

    HomeBinding().dependencies();
    ProfileBinding().dependencies();
    CommunityBinding().dependencies();
  }

  void _onCenterTap() {
    Get.to(() => const CreatePostScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: pages,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeIndex,
          onCenterTap: _onCenterTap,
        ),
      ),
    );
  }
}
