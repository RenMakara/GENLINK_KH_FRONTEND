import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import 'package:get/get.dart';

import 'features/community/presentation/screens/community_screen.dart';
import 'features/growth/presentation/screens/growth_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'main_controller.dart';
import 'shared/widgets/bottom_nav_bar.dart';
import 'shared/widgets/global_create_sheet.dart';

/// Signed-in shell. The tab order here must match [BottomNavBar]:
/// Community (0), LevelUp (1), Finance (2), Profile (3).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainController controller;
  int _lastIndex = 0;

  late final List<Widget> pages = [
    CommunityScreen(
      onNavigateTab: (index) => controller.changeIndex(index),
    ),
    GrowthScreen(onNavigateTab: (index) => controller.changeIndex(index)),
    const FinanceScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.find<MainController>();
    _lastIndex = controller.currentIndex.value;
  }

  /// Center '+' action in bottom navigation: opens the centralized Create bottom sheet.
  void _onCenterTap() {
    GlobalCreateSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = controller.currentIndex.value;
      final isForward = currentIndex > _lastIndex;
      _lastIndex = currentIndex;

      return Scaffold(
        extendBody: true,
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification is ScrollUpdateNotification) {
              final double pixels = notification.metrics.pixels;
              final double maxScroll = notification.metrics.maxScrollExtent;

              // Do not hide if we are at the very top or very bottom
              if (pixels <= 0 || pixels >= maxScroll) {
                controller.setNavBarVisibility(true);
                return false;
              }

              // Detect scroll direction
              if (notification.scrollDelta != null) {
                if (notification.scrollDelta! > 2.0) {
                  // Scrolling down — hide
                  controller.setNavBarVisibility(false);
                } else if (notification.scrollDelta! < -2.0) {
                  // Scrolling up — show
                  controller.setNavBarVisibility(true);
                }
              }
            }
            return false;
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Determine if this child is the new incoming page
              final isIncoming = child.key == ValueKey<int>(currentIndex);

              // For incoming: slide from right if forward, from left if backward
              // For outgoing: slide to left if forward, to right if backward
              Offset begin;
              if (isIncoming) {
                begin = isForward
                    ? const Offset(1.0, 0.0)
                    : const Offset(-1.0, 0.0);
              } else {
                begin = isForward
                    ? const Offset(-1.0, 0.0)
                    : const Offset(1.0, 0.0);
              }

              return SlideTransition(
                position: Tween<Offset>(
                  begin: begin,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: SizedBox.expand(
              key: ValueKey<int>(currentIndex),
              child: pages[currentIndex],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTap: controller.changeIndex,
          onCenterTap: _onCenterTap,
        ),
      );
    });
  }
}
