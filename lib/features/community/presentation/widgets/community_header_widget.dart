import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/headers/app_screen_header.dart';
import '../../../home/presentation/widgets/home_header_actions.dart';
import '../screens/community_search_screen.dart';

class CommunityHeaderWidget extends StatelessWidget
    implements PreferredSizeWidget {
  static const double standardHeaderHeight = 52.0;

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
  Size get preferredSize => const Size.fromHeight(standardHeaderHeight);

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final actions = <Widget>[
      AppHeaderActionButton(
        icon: Icons.search_rounded,
        onTap: () => Get.to(
          () => const CommunitySearchScreen(),
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

    final homeTitleWidget = isHomeScreen
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(
              titleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: semantic.primaryText,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ) ??
                  TextStyle(
                    color: semantic.primaryText,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
            ),
          )
        : null;

    return AppScreenHeader(
      title: titleText,
      titleWidget: homeTitleWidget,
      toolbarHeight: standardHeaderHeight,
      actions: actions,
    );
  }
}

