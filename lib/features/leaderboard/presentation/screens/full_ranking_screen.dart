import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/headers/app_screen_header.dart';
import '../controllers/leaderboard_controller.dart';
import '../widgets/leaderboard_user_tile.dart';

enum RankingScope { top100, myRegion, friends }

class FullRankingScreen extends StatefulWidget {
  const FullRankingScreen({super.key});

  @override
  State<FullRankingScreen> createState() => _FullRankingScreenState();
}

class _FullRankingScreenState extends State<FullRankingScreen> {
  final LeaderboardController controller = Get.find<LeaderboardController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final Rx<RankingScope> _selectedScope = RankingScope.top100.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Row(
              children: [
                AppBackButton(
                  onPressed: () {
                    if (Get.previousRoute.isNotEmpty) {
                      Get.back();
                    } else {
                      Get.offAllNamed(AppRoutes.home);
                    }
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'leaderboard.globalRanking'.tr,
                        style: textTheme.headlineSmall?.copyWith(
                          color: semantic.primaryText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'leaderboard.globalSubtitle'.tr,
                        style: textTheme.bodySmall?.copyWith(
                          color: semantic.secondaryText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                AppHeaderActionButton(
                  icon: Icons.notifications_outlined,
                  tooltip: 'notification.title'.tr,
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.entries.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: semantic.primary),
          );
        }

        if (controller.errorMessage.value != null && controller.entries.isEmpty) {
          return _buildErrorState(context);
        }

        final query = _searchQuery.value.trim().toLowerCase();
        var filteredList = controller.entries.where((entry) {
          if (query.isEmpty) return true;
          return entry.name.toLowerCase().contains(query);
        }).toList();

        // Handle scope filtering
        if (_selectedScope.value == RankingScope.friends) {
          filteredList = filteredList.where((entry) => entry.isCurrentUser).toList();
          // If no friends exist yet, gracefully fall back to full list
          if (filteredList.isEmpty) {
            filteredList = controller.entries.where((entry) {
              if (query.isEmpty) return true;
              return entry.name.toLowerCase().contains(query);
            }).toList();
          }
        } else if (_selectedScope.value == RankingScope.top100) {
          if (filteredList.length > 100) {
            filteredList = filteredList.sublist(0, 100);
          }
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          color: semantic.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            children: [
              _buildGlobalHeroBanner(context),
              const SizedBox(height: AppSpacing.md),
              _buildScopeTabs(context),
              const SizedBox(height: AppSpacing.md),
              _buildSearchBar(context),
              const SizedBox(height: AppSpacing.md),
              if (filteredList.isEmpty)
                _buildEmptySearchState(context)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = filteredList[index];
                    return LeaderboardUserTile(
                      entry: entry,
                      isCard: true,
                      showPointsLabel: true,
                      showMedalIcon: entry.rank <= 3,
                      onTap: () => Get.toNamed(
                        AppRoutes.leaderboardProfile,
                        arguments: entry,
                      ),
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              _buildGlobalFooterBanner(context),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      }),
    );
  }

  /// Global Hero Banner with cosmic gradient and stylized globe
  Widget _buildGlobalHeroBanner(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF1E1B4B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle globe decoration on right
          Positioned(
            right: -10,
            bottom: -20,
            top: -20,
            child: Opacity(
              opacity: 0.22,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF38BDF8), Colors.transparent],
                  ),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  size: 110,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFBBF24),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'leaderboard.globalHeroTitle'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'leaderboard.globalHeroSubtitle'.tr,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'leaderboard.globalTag'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Scope filter tabs: [Top 100] [My Region] [Friends]
  Widget _buildScopeTabs(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabs = [
      (RankingScope.top100, 'leaderboard.top100'.tr),
      (RankingScope.myRegion, 'leaderboard.myRegion'.tr),
      (RankingScope.friends, 'leaderboard.friends'.tr),
    ];

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? semantic.surface : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? semantic.borderSubtle : semantic.borderSubtle.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedScope.value == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedScope.value = tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? semantic.surfaceElevated : const Color(0xFF18191B))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : const [],
                ),
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? semantic.primaryText : Colors.white)
                        : semantic.secondaryText,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Instant live search bar
  Widget _buildSearchBar(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? semantic.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? semantic.borderSubtle : semantic.borderSubtle.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _searchQuery.value = val,
        style: TextStyle(
          color: semantic.primaryText,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'leaderboard.searchUser'.tr,
          hintStyle: TextStyle(
            color: semantic.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: semantic.textMuted,
          ),
          suffixIcon: _searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: semantic.textMuted,
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery.value = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  /// Globe motivational banner at the bottom
  Widget _buildGlobalFooterBanner(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Color.alphaBlend(
                AppColors.brandPrimary.withValues(alpha: 0.10),
                semantic.surface,
              )
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark
              ? semantic.borderSubtle
              : const Color(0xFFBBF7D0),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.public_rounded,
              color: Color(0xFF16A34A),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'leaderboard.globalFooter'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? semantic.primaryText : const Color(0xFF166534),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final semantic = context.semanticColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value!,
              textAlign: TextAlign.center,
              style: TextStyle(color: semantic.primaryText, fontSize: 14),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: semantic.primary,
                foregroundColor: semantic.textInverse,
              ),
              onPressed: controller.load,
              child: Text('common.retry'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(BuildContext context) {
    final semantic = context.semanticColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 48,
            color: semantic.borderStrong,
          ),
          const SizedBox(height: 12),
          Text(
            'leaderboard.noData'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: semantic.secondaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
