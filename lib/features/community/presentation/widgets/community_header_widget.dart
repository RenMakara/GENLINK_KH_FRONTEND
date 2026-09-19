import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/headers/app_screen_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/presentation/widgets/home_header_actions.dart';
import '../screens/community_search_screen.dart';

class CommunityHeaderWidget extends StatelessWidget
    implements PreferredSizeWidget {
  static const double standardHeaderHeight = 52.0;
  static const double homeHeaderHeight = 76.0;

  final String activeCategory;
  final String Function()? activeCategoryBuilder;
  final bool isHomeScreen;

  const CommunityHeaderWidget({
    super.key,
    required this.activeCategory,
    this.activeCategoryBuilder,
    this.isHomeScreen = true,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(isHomeScreen ? homeHeaderHeight : standardHeaderHeight);

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AppHeaderActionButton(
        icon: Icons.search_rounded,
        onTap: () => Get.to(
          () => CommunitySearchScreen(
            activeTab: activeCategoryBuilder?.call() ?? activeCategory,
          ),
        ),
        tooltip:
            'community.search'.tr.isNotEmpty &&
                'community.search'.tr != 'community.search'
            ? 'community.search'.tr
            : 'Search',
      ),
      const AppHeaderNotificationButton(),
      const AppHeaderChatButton(),
    ];

    final titleText = isHomeScreen
        ? ('nav.home'.tr.isNotEmpty && 'nav.home'.tr != 'nav.home'
              ? 'nav.home'.tr
              : 'Home')
        : ('community.title'.tr.isNotEmpty &&
                  'community.title'.tr != 'community.title'
              ? 'community.title'.tr
              : 'Community');

    return AppScreenHeader(
      title: titleText,
      titleWidget: isHomeScreen ? _buildHomeTitle() : null,
      toolbarHeight: isHomeScreen ? homeHeaderHeight : standardHeaderHeight,
      actions: actions,
    );
  }

  Widget _buildHomeTitle() {
    final greeting = _homeGreeting();
    if (!Get.isRegistered<AuthController>()) {
      return _HomeGreetingTitle(greeting: greeting, name: 'Guest');
    }

    final authController = Get.find<AuthController>();
    return Obx(() {
      final user = authController.currentUser.value;
      final fullName = user?.fullName.trim() ?? '';
      final username = user?.username.trim() ?? '';
      final name = fullName.isNotEmpty && fullName != 'Guest'
          ? fullName
          : (username.isNotEmpty ? username : 'Guest');
      return _HomeGreetingTitle(greeting: greeting, name: name);
    });
  }

  String _homeGreeting() {
    final hour = DateTime.now().hour;
    final key = hour < 12
        ? 'home.goodMorning'
        : (hour < 18 ? 'home.goodAfternoon' : 'home.goodEvening');
    final translated = key.tr;
    final greeting = translated.isNotEmpty && translated != key
        ? translated
        : (hour < 12
              ? 'Good morning'
              : (hour < 18 ? 'Good afternoon' : 'Good evening'));
    return hour < 12 ? '$greeting ☀️' : greeting;
  }
}

class _HomeGreetingTitle extends StatelessWidget {
  const _HomeGreetingTitle({required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                theme.textTheme.bodyLarge?.copyWith(
                  color: semantic.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                ) ??
                TextStyle(
                  color: semantic.secondaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                theme.textTheme.headlineSmall?.copyWith(
                  color: semantic.primaryText,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.12,
                ) ??
                TextStyle(
                  color: semantic.primaryText,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.12,
                ),
          ),
        ],
      ),
    );
  }
}
