import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/widgets/avatar/app_avatar.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../domain/models/community_models.dart';
import '../../domain/models/community_post_model.dart';
import '../../domain/models/search_models.dart';
import '../controllers/community_search_controller.dart';

class CommunitySearchScreen extends StatefulWidget {
  final String activeTab;
  final CommunitySearchController? controller;

  const CommunitySearchScreen({
    super.key,
    this.activeTab = 'all',
    this.controller,
  });

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late final CommunitySearchController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();

    if (widget.controller != null) {
      controller = widget.controller!;
    } else if (Get.isRegistered<CommunitySearchController>()) {
      controller = Get.find<CommunitySearchController>();
    } else {
      controller = Get.put(CommunitySearchController());
      _ownsController = true;
    }

    // Map initial tab if explicitly provided and not default
    final lower = widget.activeTab.toLowerCase();
    if (lower.contains('event')) {
      controller.selectedCategory.value = SearchCategory.events;
    } else if (lower.contains('forum') || lower.contains('discussion')) {
      controller.selectedCategory.value = SearchCategory.forum;
    } else if (lower.contains('post')) {
      controller.selectedCategory.value = SearchCategory.posts;
    } else if (lower.contains('people') || lower.contains('user')) {
      controller.selectedCategory.value = SearchCategory.people;
    } else {
      controller.selectedCategory.value = SearchCategory.all;
    }

    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    if (_ownsController && Get.isRegistered<CommunitySearchController>()) {
      Get.delete<CommunitySearchController>();
    }
    super.dispose();
  }

  void _applyQuery(String newQuery, {bool submit = true}) {
    _textController.text = newQuery;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: newQuery.length),
    );
    if (submit) {
      _focusNode.unfocus();
      controller.submitSearch(newQuery);
    } else {
      controller.onQueryChanged(newQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final scaffoldBg =
        isDark ? AppColors.darkBgPrimary : AppColors.lightSurfacePrimary;
    final searchBarBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final searchBarBorder =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const Center(child: AppBackButton()),
        leadingWidth: 58,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: textPrimary,
              onChanged: controller.onQueryChanged,
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _focusNode.unfocus();
                  controller.submitSearch(val.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'community.searchHint'.tr,
                hintStyle: TextStyle(
                  color: textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: textSecondary,
                  size: 20,
                ),
                suffixIcon: Obx(() {
                  if (controller.query.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: textSecondary,
                      size: 18,
                    ),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () {
                      _textController.clear();
                      controller.clearQuery();
                      _focusNode.requestFocus();
                    },
                  );
                }),
                isDense: true,
                filled: true,
                fillColor: searchBarBg,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: searchBarBorder,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkBorderStrong
                        : AppColors.lightBorderStrong,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        final query = controller.query.value.trim();
        final isSearching = query.isNotEmpty;
        final isSubmitted = controller.isSubmitted.value;

        if (!isSearching) {
          return _buildIdleState();
        }

        if (!isSubmitted) {
          // STATE 1: TYPING — Lightweight suggestions UI
          return _buildTypingSuggestionsView(query);
        }

        // STATE 2: SUBMITTED SEARCH — Full result categories & cards
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            _buildCategoryTabs(),
            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? AppColors.darkBorderSubtle
                  : AppColors.lightBorderSubtle,
            ),
            Expanded(
              child: _buildSearchResultsArea(query),
            ),
          ],
        );
      }),
    );
  }

  // Lightweight suggestions UI while typing (STATE 1)
  Widget _buildTypingSuggestionsView(String query) {
    if (controller.isLoading.value && controller.searchResults.value == null) {
      return _buildSuggestionLoadingSkeleton();
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _buildCompactErrorState();
    }

    final querySuggestions = controller.getQuerySuggestions();
    final peopleSuggestions = controller.getPeopleSuggestions();
    final results = controller.searchResults.value;

    final hasNoRealResults = results != null &&
        results.isEmpty &&
        peopleSuggestions.isEmpty &&
        (querySuggestions.isEmpty ||
            (querySuggestions.length == 1 &&
                querySuggestions.first.toLowerCase() == query.toLowerCase() &&
                !controller.recentSearches
                    .any((s) => s.toLowerCase() == query.toLowerCase())));

    if (hasNoRealResults) {
      return _buildCompactNoSuggestions();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (querySuggestions.isNotEmpty) ...[
            _buildSuggestionSectionHeader('community.suggestions'.tr),
            const SizedBox(height: 4),
            ...querySuggestions.map((s) => _buildQuerySuggestionTile(s)),
            const SizedBox(height: 16),
          ],
          if (peopleSuggestions.isNotEmpty) ...[
            _buildSuggestionSectionHeader('community.searchPeople'.tr),
            const SizedBox(height: 4),
            ...peopleSuggestions.map((u) => _buildCompactPersonSuggestion(u)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildQuerySuggestionTile(String suggestion) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: () => _applyQuery(suggestion, submit: true),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: textMuted,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              color: textMuted,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPersonSuggestion(UserSearchResultModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => controller.openUserProfile(user),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          children: [
            AppAvatar(
              imageUrl: user.avatarUrl,
              name: user.fullName.isNotEmpty ? user.fullName : user.username,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.username.startsWith('@')
                        ? user.username
                        : '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactNoSuggestions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Text(
          'community.noSuggestions'.tr,
          style: TextStyle(
            color: textMuted,
            fontSize: 13.5,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'community.suggestionsError'.tr,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: controller.retry,
              child: Text(
                'community.retry'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionLoadingSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        return Row(
          children: [
            Container(
              width: index % 2 == 0 ? 18 : 32,
              height: index % 2 == 0 ? 18 : 32,
              decoration: BoxDecoration(
                color: skeletonColor,
                shape: index % 2 == 0 ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: index % 2 == 0 ? BorderRadius.circular(4) : null,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 120.0 + (index * 25.0),
              height: 12,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResultsArea(String query) {
    if (controller.isLoading.value) {
      return _buildLoadingSkeleton();
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _buildErrorState();
    }

    final results = controller.searchResults.value;
    if (results == null || results.isEmpty) {
      return _buildNoResultsState(query);
    }

    return _buildResultsView(results);
  }

  // Compact horizontal category selector with GenLink Black/White/Neutral identity
  Widget _buildCategoryTabs() {
    // Categories strictly kept: All, People, Posts, Events, Forum (Media removed)
    const categories = [
      SearchCategory.all,
      SearchCategory.people,
      SearchCategory.posts,
      SearchCategory.events,
      SearchCategory.forum,
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Obx(() {
            final isSelected = controller.selectedCategory.value == cat;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            // GenLink Design Tokens:
            // Light Mode: selected = Black/Dark Neutral pill; unselected = Light neutral
            // Dark Mode: selected = White/Light Neutral pill; unselected = Dark charcoal
            final activeBg = isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary;
            final activeText = isDark
                ? AppColors.darkTextInverse
                : AppColors.lightTextInverse;
            final activeBorder = activeBg;

            final inactiveBg = isDark
                ? AppColors.darkSurfaceSecondary
                : AppColors.lightBgSecondary;
            final inactiveText = isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary;
            final inactiveBorder = isDark
                ? AppColors.darkBorderSubtle
                : AppColors.lightBorderSubtle;

            return InkWell(
              onTap: () => controller.selectCategory(cat),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : inactiveBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? activeBorder : inactiveBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  cat.label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: isSelected ? activeText : inactiveText,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  // Idle state: Recent Searches + Trending Hashtags
  Widget _buildIdleState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Obx(() {
      final recent = controller.recentSearches;
      final trending = controller.trendingHashtags;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recent.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'community.recentSearches'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.clearAllRecentSearches,
                    child: Text(
                      'community.clear'.tr,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...recent.map((item) {
                return InkWell(
                  onTap: () => _applyQuery(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded,
                            color: textMuted, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style:
                                TextStyle(color: textPrimary, fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.removeRecentSearch(item),
                          child: Icon(
                            Icons.close_rounded,
                            color: textMuted,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 18),
            ],

            if (trending.isNotEmpty) ...[
              Row(
                children: [
                  const Text('🔥 ', style: TextStyle(fontSize: 14)),
                  Text(
                    'community.trending'.tr,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: trending.map((tag) {
                  return InkWell(
                    onTap: () => _applyQuery(tag),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderSubtle),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      );
    });
  }

  // Loading skeleton matching card layouts
  Widget _buildLoadingSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final skeletonColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 140,
                      height: 10,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Error state with retry
  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: textMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'community.searchError'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'community.searchErrorSub'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                foregroundColor: isDark
                    ? AppColors.darkTextInverse
                    : AppColors.lightTextInverse,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'community.retry'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty results view
  Widget _buildNoResultsState(String query) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final bgIcon =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final borderIcon =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: bgIcon,
                shape: BoxShape.circle,
                border: Border.all(color: borderIcon),
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'community.noResultsFound'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'community.noResultsForQuery'.trParams({'query': query}),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'community.trySearchingAnother'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  // Active Results View
  Widget _buildResultsView(CombinedSearchResults results) {
    switch (controller.selectedCategory.value) {
      case SearchCategory.people:
        return _buildPeopleList(results.people);
      case SearchCategory.posts:
        return _buildPostsList(results.posts);
      case SearchCategory.events:
        return _buildEventsList(results.events);
      case SearchCategory.forum:
        return _buildForumList(results.discussions);
      case SearchCategory.media:
        return _buildNoResultsState(controller.query.value.trim());
      case SearchCategory.all:
        return _buildAllSections(results);
    }
  }

  // Unified "ALL" category view with sections
  Widget _buildAllSections(CombinedSearchResults results) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (results.people.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'community.searchPeople'.tr,
              count: results.totalPeople > 0
                  ? results.totalPeople
                  : results.people.length,
              onSeeAll: () =>
                  controller.selectCategory(SearchCategory.people),
            ),
            const SizedBox(height: 8),
            ...results.people.take(3).map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPersonCard(u),
                )),
            const SizedBox(height: 10),
          ],
          if (results.posts.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'community.searchPosts'.tr,
              count: results.totalPosts > 0
                  ? results.totalPosts
                  : results.posts.length,
              onSeeAll: () =>
                  controller.selectCategory(SearchCategory.posts),
            ),
            const SizedBox(height: 8),
            ...results.posts.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPostCard(p),
                )),
            const SizedBox(height: 10),
          ],
          if (results.events.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'community.searchEvents'.tr,
              count: results.totalEvents > 0
                  ? results.totalEvents
                  : results.events.length,
              onSeeAll: () =>
                  controller.selectCategory(SearchCategory.events),
            ),
            const SizedBox(height: 8),
            ...results.events.take(3).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildEventCard(e),
                )),
            const SizedBox(height: 10),
          ],
          if (results.discussions.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'community.searchForum'.tr,
              count: results.totalDiscussions > 0
                  ? results.totalDiscussions
                  : results.discussions.length,
              onSeeAll: () =>
                  controller.selectCategory(SearchCategory.forum),
            ),
            const SizedBox(height: 8),
            ...results.discussions.take(3).map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildForumCard(d),
                )),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required VoidCallback onSeeAll,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final countBg =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightBgSecondary;
    final countBorder =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final countText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: countBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: countBorder),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: countText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'community.seeAll'.tr,
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.brandPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // People List
  Widget _buildPeopleList(List<UserSearchResultModel> people) {
    if (people.isEmpty) {
      return _buildNoResultsState(controller.query.value.trim());
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: people.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _buildPersonCard(people[index]),
    );
  }

  Widget _buildPersonCard(UserSearchResultModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final border =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final badgeBg = isDark
        ? AppColors.brandPrimary.withValues(alpha: 0.14)
        : AppColors.brandPrimary.withValues(alpha: 0.10);
    final badgeBorder = isDark
        ? AppColors.brandPrimary.withValues(alpha: 0.28)
        : AppColors.brandPrimary.withValues(alpha: 0.20);

    final cleanUsername = user.username.trim().replaceFirst(RegExp(r'^@+'), '');
    final displayUsername = cleanUsername.isNotEmpty ? '@$cleanUsername' : '';
    final displayName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : (cleanUsername.isNotEmpty ? cleanUsername : 'GenLink User');

    final roleText = user.workStatus?.trim().isNotEmpty == true
        ? user.workStatus!.trim()
        : (user.universityName?.trim().isNotEmpty == true
            ? user.universityName!.trim()
            : (user.bio?.trim().isNotEmpty == true ? user.bio!.trim() : ''));

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => controller.openUserProfile(user),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              AppAvatar(
                imageUrl: user.avatarUrl,
                name: displayName,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (user.level > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: badgeBorder, width: 0.8),
                            ),
                            child: Text(
                              'Lv.${user.level}',
                              style: const TextStyle(
                                color: AppColors.brandPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (displayUsername.isNotEmpty) ...[
                      const SizedBox(height: 1.5),
                      Text(
                        displayUsername,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    if (roleText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        roleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Posts List
  Widget _buildPostsList(List<CommunityPostModel> posts) {
    if (posts.isEmpty) {
      return _buildNoResultsState(controller.query.value.trim());
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _buildPostCard(posts[index]),
    );
  }

  Widget _buildPostCard(CommunityPostModel post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    final subtitle = post.authorTag.isNotEmpty
        ? '${post.authorTag} • ${post.timeAgo}'
        : post.timeAgo;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => controller.openPostComments(context, post),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderSubtle, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AppAvatar(
                    imageUrl: post.authorAvatar,
                    name: post.authorName,
                    size: 34,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrls.first,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 13.5,
                    color: textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 13.5,
                    color: textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Events List
  Widget _buildEventsList(List<EventModel> events) {
    if (events.isEmpty) {
      return _buildNoResultsState(controller.query.value.trim());
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _buildEventCard(events[index]),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => controller.openEvent(event),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderSubtle, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorderSubtle
                      : AppColors.lightBgSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: event.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          event.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Icon(
                            Icons.event_available_rounded,
                            color: textSecondary,
                            size: 22,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.event_available_rounded,
                        color: textSecondary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (event.dateString.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.dateString,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: textMuted,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location.isNotEmpty
                                ? event.location
                                : event.eventType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 86),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.lightBgSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.eventType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Forum Discussions List
  Widget _buildForumList(List<ForumTopicModel> discussions) {
    if (discussions.isEmpty) {
      return _buildNoResultsState(controller.query.value.trim());
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: discussions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _buildForumCard(discussions[index]),
    );
  }

  Widget _buildForumCard(ForumTopicModel topic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => controller.openDiscussion(topic),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderSubtle, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      topic.category,
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    topic.timeAgo,
                    style: TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                topic.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (topic.content.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  topic.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topic.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 13,
                    color: textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${topic.upvotes}',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 13,
                    color: textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${topic.repliesCount}',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
