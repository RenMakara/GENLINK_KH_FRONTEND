import 'package:flutter/material.dart';
import 'package:genlink_frontend/features/finance/finance_screen.dart';
import 'package:get/get.dart';

import 'features/community/presentation/screens/community_screen.dart';
import 'features/community/presentation/widgets/community_creation_flow.dart';
import 'features/levelup/levelup_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'main_controller.dart';
import 'shared/widgets/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainController controller;

  late final List<Widget> pages = [
    KeyedSubtree(
      key: const PageStorageKey<String>('page_home'),
      child: PageStorage(
        bucket: PageStorageBucket(),
        child: CommunityScreen(
          isHomeScreen: true,
          onNavigateTab: (index) => controller.changeIndex(index),
        ),
      ),
    ),
    KeyedSubtree(
      key: const PageStorageKey<String>('page_growth'),
      child: PageStorage(
        bucket: PageStorageBucket(),
        child: LevelUpScreen(
          onNavigateTab: (index) => controller.changeIndex(index),
        ),
      ),
    ),
    KeyedSubtree(
      key: const PageStorageKey<String>('page_finance'),
      child: PageStorage(
        bucket: PageStorageBucket(),
        child: const FinanceScreen(),
      ),
    ),
    KeyedSubtree(
      key: const PageStorageKey<String>('page_profile'),
      child: PageStorage(
        bucket: PageStorageBucket(),
        child: const ProfileScreen(),
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.find<MainController>();
  }

  void _onCenterTap() {
    CommunityCreationFlow.openCreatePost(context);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = controller.currentIndex.value;

      return Scaffold(
        extendBody: true,
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification.metrics.axis != Axis.vertical) {
              return false;
            }

            if (notification is ScrollUpdateNotification) {
              final double pixels = notification.metrics.pixels;
              final double maxScroll = notification.metrics.maxScrollExtent;

              if (pixels <= 0 || pixels >= maxScroll) {
                controller.setNavBarVisibility(true);
                return false;
              }

              if (notification.scrollDelta != null) {
                if (notification.scrollDelta! > 12.0 && pixels > 80.0) {
                  controller.setNavBarVisibility(false);
                } else if (notification.scrollDelta! < -8.0) {
                  controller.setNavBarVisibility(true);
                }
              }
            }
            return false;
          },
          child: FadeIndexedStack(index: currentIndex, children: pages),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTap: (index) {
            controller.changeIndex(index);
          },
          onCenterTap: _onCenterTap,
        ),
      );
    });
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 200);
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _reverseFadeAnimation;
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: _transitionDuration,
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _reverseFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAnimating = _controller.isAnimating;

    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final isCurrent = i == _currentIndex;
        final isPrevious = i == _previousIndex && isAnimating;

        if (!isCurrent && !isPrevious) {
          return Offstage(
            offstage: true,
            child: HeroMode(
              enabled: false,
              child: TickerMode(enabled: false, child: widget.children[i]),
            ),
          );
        }

        if (isPrevious) {
          return IgnorePointer(
            child: FadeTransition(
              opacity: _reverseFadeAnimation,
              child: HeroMode(
                enabled: false,
                child: TickerMode(enabled: false, child: widget.children[i]),
              ),
            ),
          );
        }

        return IgnorePointer(
          ignoring: isAnimating,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: HeroMode(
              enabled: true,
              child: TickerMode(enabled: true, child: widget.children[i]),
            ),
          ),
        );
      }),
    );
  }
}
