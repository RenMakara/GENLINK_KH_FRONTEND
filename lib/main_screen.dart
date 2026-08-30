import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'features/community/presentation/screens/community_screen.dart';
import 'features/community/presentation/screens/create_post_screen.dart';
import 'features/finance/presentation/screens/finance_home/screens/finance_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
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
  int _lastIndex = 0;

  late final List<Widget> pages = [
    HomeScreen(onNavigateTab: (index) => controller.changeIndex(index)),
    const CommunityScreen(),
    const FinanceScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.find<MainController>();
    _lastIndex = controller.currentIndex.value;
  }

  /// Center '+' action in bottom navigation: opens Post Composer screen.
  void _onCenterTap() {
    Get.to(
      () => const CreatePostScreen(),
      routeName: '/CreatePostScreen',
      transition: Transition.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
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
                final isIncoming = child.key == ValueKey<int>(currentIndex);

                Offset begin;
                if (isIncoming) {
                  begin = isForward ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
                } else {
                  begin = isForward ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
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
      },
    );
  }
}
