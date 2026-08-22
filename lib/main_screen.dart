import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'features/community/presentation/controllers/community_controller.dart';
import 'features/community/presentation/screens/community_screen.dart';
import 'features/community/presentation/screens/create_discussion_screen.dart';
import 'features/community/presentation/screens/create_event_screen.dart';
import 'features/community/presentation/screens/create_opportunity_screen.dart';
import 'features/community/presentation/screens/create_post_screen.dart';
import 'features/community/presentation/widgets/story_creation_picker_sheet.dart';
import 'features/finance/presentation/screens/Finance Home/screens/finance_screen.dart';
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
  }

  /// Context-aware "+" tap handler.
  ///
  /// When the user is on the Community tab (index 1), the action is determined
  /// by which sub-tab is currently active in [CommunityController].
  /// On any other tab, it defaults to Create Post.
  void _onCenterTap() {
    if (controller.currentIndex.value == 1) {
      // Currently on the Community tab — route by active community sub-tab
      final CommunityController? commController =
          Get.isRegistered<CommunityController>()
          ? Get.find<CommunityController>()
          : null;

      final activeTab = commController?.selectedCategory.value ?? 'Feed';

      switch (activeTab) {
        case 'Forum':
          Get.to(() => const CreateDiscussionScreen());
          break;
        case 'Career':
          Get.to(() => const CreateOpportunityScreen());
          break;
        case 'Event':
          Get.to(() => const CreateEventScreen());
          break;
        case 'Feed':
        default:
          _showFeedCreateMenu(context);
      }
    } else {
      // Not on Community tab — open Feed Create Post
      Get.to(() => const CreatePostScreen());
    }
  }

  void _showFeedCreateMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161616) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.post_add, color: textPrimary),
              title: Text(
                'community.createPost'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => const CreatePostScreen());
              },
            ),
            ListTile(
              leading: Icon(Icons.amp_stories_outlined, color: textPrimary),
              title: Text(
                'community.createStory'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                StoryCreationPickerSheet.show(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.event_available_outlined, color: textPrimary),
              title: Text(
                'community.createEvent'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => const CreateEventScreen());
              },
            ),
          ],
        ),
      ),
    );
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
