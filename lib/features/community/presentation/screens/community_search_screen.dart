import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../design_system/colors/app_colors.dart';

/// Community Search Screen
///
/// Clean, fast, and modern search interface inspired by modern social platforms.
/// Features a single category navigation bar, compact recent search history (max 3 items),
/// lightweight category & trending chips, and instant live search results.
class CommunitySearchScreen extends StatefulWidget {
  final String activeTab;

  const CommunitySearchScreen({
    super.key,
    required this.activeTab,
  });

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  bool _isLoading = false;

  final List<String> _recentSearches = [
    'Flutter Workshop',
    'ABA Internship',
    'CADT Hackathon',
    'Senior Dev Mentors',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String text) {
    setState(() {
      _query = text;
      _isLoading = text.trim().isNotEmpty;
    });

    if (text.trim().isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _addToRecentSearches(String item) {
    if (item.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(item);
      _recentSearches.insert(0, item);
    });
  }

  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: TextStyle(color: textPrimary, fontSize: 14),
              onChanged: _onQueryChanged,
              onSubmitted: (val) => _addToRecentSearches(val),
              decoration: InputDecoration(
                hintText: 'community.searchHint'.tr,
                hintStyle: TextStyle(color: textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: textMuted, size: 19),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: surfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: borderSubtle, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: borderSubtle, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.35) : AppColors.lightBorderStrong,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ── Dynamic Body: Idle State vs Live Results ──
          Expanded(
            child: _query.trim().isEmpty
                ? _buildIdleState()
                : _isLoading
                    ? _buildLoadingState()
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Idle State: Compact Recent Searches (Max 3), Modern Categories & Trending
  // ---------------------------------------------------------------------------
  Widget _buildIdleState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white70 : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    // Show only the latest 3 recent searches
    final displayRecent = _recentSearches.take(3).toList();

    final trendingHashtags = [
      '#Flutter',
      '#Internship',
      '#Hackathon',
      '#AI',
      '#Community',
      '#CADT',
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Recent Searches (Compact, Max 3) ──
          if (displayRecent.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'community.recentSearches'.tr,
                  style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: _clearAllRecentSearches,
                  child: Text(
                    'community.clear'.tr,
                    style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...displayRecent.map((item) {
              return InkWell(
                onTap: () {
                  _searchController.text = item;
                  _onQueryChanged(item);
                  _addToRecentSearches(item);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: textMuted, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(color: textPrimary, fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _recentSearches.remove(item)),
                        child: Icon(Icons.close_rounded, color: textMuted, size: 15),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 18),
          ],

          // ── 2. Trending Topics (Compact Chips) ──
          Text(
            'community.trending'.tr,
            style: TextStyle(color: textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendingHashtags.map((tag) {
              return InkWell(
                onTap: () {
                  _searchController.text = tag;
                  _onQueryChanged(tag);
                  _addToRecentSearches(tag);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lightweight Loading State
  // ---------------------------------------------------------------------------
  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final skeletonColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(10),
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
                      width: 120,
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

  // ---------------------------------------------------------------------------
  // Live Search Results List
  // ---------------------------------------------------------------------------
  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surfaceSecondary = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfacePrimary;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final iconBgColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBgSecondary;
    final badgeBgColor = isDark ? Colors.white.withValues(alpha: 0.10) : AppColors.lightBgSecondary;

    final results = [
      {
        'title': 'Flutter Workshop 2026 @ CADT',
        'subtitle': 'Cross-platform app development with Riverpod & M3',
        'category': 'Events',
      },
      {
        'title': 'Junior Flutter Developer - ABA Bank',
        'subtitle': 'Full-time • Phnom Penh • \$600 - \$900/mo',
        'category': 'Jobs',
      },
      {
        'title': 'Sokchea Lim',
        'subtitle': 'Software Engineering Student @ CADT 2026',
        'category': 'People',
      },
      {
        'title': 'Cambodia Flutter Developers',
        'subtitle': 'Community group • 2.4k members',
        'category': 'Communities',
      },
      {
        'title': 'Best practices for Clean Architecture in Flutter',
        'subtitle': 'Discussion thread • 34 comments',
        'category': 'Posts',
      },
    ];

    // Filter by query match
    final filtered = results.where((item) {
      return item['title']!.toLowerCase().contains(_query.toLowerCase()) ||
          item['subtitle']!.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, color: textMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                'community.noResultsFound'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
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

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final res = filtered[idx];
        final rawCat = res['category']!;

        // Map category to concise badge text
        String badgeText = rawCat;
        IconData catIcon = Icons.article_outlined;

        if (rawCat == 'People') {
          badgeText = 'People';
          catIcon = Icons.person_outline_rounded;
        } else if (rawCat == 'Jobs') {
          badgeText = 'Job';
          catIcon = Icons.work_outline_rounded;
        } else if (rawCat == 'Events') {
          badgeText = 'Event';
          catIcon = Icons.event_outlined;
        } else if (rawCat == 'Communities') {
          badgeText = 'Community';
          catIcon = Icons.groups_outlined;
        } else if (rawCat == 'Posts') {
          badgeText = 'Post';
          catIcon = Icons.article_outlined;
        }

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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, color: textSecondary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res['title']!,
                      style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res['subtitle']!,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderSubtle),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
