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
  late final List<Widget Function()> _pageBuilders;
  final List<Widget?> _pages = List<Widget?>.filled(
    MainController.tabCount,
    null,
  );

  @override
  void initState() {
    super.initState();
    controller = Get.find<MainController>();
    _pageBuilders = [
      () => KeyedSubtree(
        key: const PageStorageKey<String>('page_home'),
        child: PageStorage(
          bucket: PageStorageBucket(),
          child: CommunityScreen(
            isHomeScreen: true,
            onNavigateTab: controller.changeIndex,
          ),
        ),
      ),
      () => KeyedSubtree(
        key: const PageStorageKey<String>('page_growth'),
        child: PageStorage(
          bucket: PageStorageBucket(),
          child: LevelUpScreen(onNavigateTab: controller.changeIndex),
        ),
      ),
      () => KeyedSubtree(
        key: PageStorageKey<String>('page_finance'),
        child: PageStorage(
          bucket: PageStorageBucket(),
          child: const FinanceScreen(),
        ),
      ),
      () => KeyedSubtree(
        key: PageStorageKey<String>('page_profile'),
        child: PageStorage(
          bucket: PageStorageBucket(),
          child: const ProfileScreen(),
        ),
      ),
    ];
  }

  void _onCenterTap() {
    CommunityCreationFlow.openCreatePost(context);
  }

  Widget _pageAt(int index) {
    return _pages[index] ??= _pageBuilders[index]();
  }

  List<Widget> _pageSlots(int currentIndex) {
    return List<Widget>.generate(_pageBuilders.length, (index) {
      // Keep visited pages alive so scroll position and form state survive tab
      // switches, but do not build every feature on the first frame.
      if (index == currentIndex || _pages[index] != null) {
        return _pageAt(index);
      }
      return SizedBox.shrink(
        key: ValueKey<String>('unvisited-main-page-$index'),
      );
    });
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

            // Keep navigation persistent on the secondary destinations. These
            // screens contain forms, dashboards, and detail flows where
            // hiding the only tab switcher can make the app feel stuck. The
            // feed can still reclaim vertical space while the user browses.
            if (controller.currentIndex.value != MainController.homeIndex) {
              controller.setNavBarVisibility(true);
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
          child: FadeIndexedStack(
            index: currentIndex,
            children: _pageSlots(currentIndex),
          ),
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
    _currentIndex = _normalizedIndex(widget.index);
    _previousIndex = _currentIndex;
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
    if (status == AnimationStatus.completed && mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = _normalizedIndex(widget.index);
    if (nextIndex != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = nextIndex;
      _controller.forward(from: 0.0);
    }
  }

  int _normalizedIndex(int index) {
    if (widget.children.isEmpty) return 0;
    return index.clamp(0, widget.children.length - 1);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();

    final isAnimating = _controller.isAnimating;
    final hasPreviousLayer = isAnimating && _previousIndex != _currentIndex;
    final visibleIndices = <int>{_currentIndex};
    if (hasPreviousLayer) visibleIndices.add(_previousIndex);

    // Keep the same wrapper types around each page for its entire lifetime.
    // Previously the active/previous pages used IgnorePointer/FadeTransition
    // while animating and Offstage after the fade; that changed the element
    // tree and disposed stateful pages (including the Home feed scrollable).
    // Keys preserve each page when its Stack position changes during a fade.
    final displayOrder = <int>[
      for (var i = 0; i < widget.children.length; i++)
        if (!visibleIndices.contains(i)) i,
      if (hasPreviousLayer) _previousIndex,
      _currentIndex,
    ];
    final layers = displayOrder
        .map((index) {
          final isCurrent = index == _currentIndex;
          final isPrevious = hasPreviousLayer && index == _previousIndex;
          return KeyedSubtree(
            key: ValueKey<String>('fade-indexed-stack-child-$index'),
            child: Offstage(
              offstage: !visibleIndices.contains(index),
              child: IgnorePointer(
                ignoring: !isCurrent || isAnimating,
                child: FadeTransition(
                  opacity: isPrevious ? _reverseFadeAnimation : _fadeAnimation,
                  child: HeroMode(
                    enabled: isCurrent,
                    child: TickerMode(
                      enabled: isCurrent,
                      child: widget.children[index],
                    ),
                  ),
                ),
              ),
            ),
          );
        })
        .toList(growable: false);

    return Stack(fit: StackFit.expand, children: layers);
  }
}
