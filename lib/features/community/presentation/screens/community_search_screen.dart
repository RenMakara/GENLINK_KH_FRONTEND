import 'package:flutter/material.dart';
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
  late String _selectedCategory;
  bool _isLoading = false;

  final List<String> _recentSearches = [
    'Flutter Workshop',
    'ABA Internship',
    'CADT Hackathon',
    'Senior Dev Mentors',
  ];

  // Single unified navigation/filter bar
  final List<String> _categories = [
    'All',
    'Posts',
    'People',
    'Events',
    'Jobs',
    'Communities',
  ];

  @override
  void initState() {
    super.initState();
    // Map initial tab if matched, default to 'All'
    _selectedCategory = _categories.firstWhere(
      (c) => c.toLowerCase() == widget.activeTab.toLowerCase(),
      orElse: () => 'All',
    );
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
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 42,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppColors.communityAccent.withValues(alpha: 0.50)
                  : AppColors.darkBorderSubtle,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.darkTextMuted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: _onQueryChanged,
                  onSubmitted: (val) => _addToRecentSearches(val),
                  decoration: const InputDecoration(
                    hintText: 'Search posts, people, jobs, events...',
                    hintStyle: TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _onQueryChanged('');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Single Unified Category Filter Bar ──
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final category = _categories[i];
                final isSelected = _selectedCategory == category;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = category),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.communityAccent
                          : AppColors.darkSurfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.communityAccent
                            : AppColors.darkBorderSubtle,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

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
    // Show only the latest 3 recent searches
    final displayRecent = _recentSearches.take(3).toList();

    final exploreCategories = [
      (Icons.article_outlined, 'Posts'),
      (Icons.people_outline_rounded, 'People'),
      (Icons.groups_outlined, 'Communities'),
      (Icons.work_outline_rounded, 'Jobs'),
      (Icons.event_outlined, 'Events'),
    ];

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
                const Text(
                  "Recent Searches",
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: _clearAllRecentSearches,
                  child: const Text(
                    "Clear",
                    style: TextStyle(color: AppColors.communityAccent, fontSize: 12, fontWeight: FontWeight.w600),
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
                      const Icon(Icons.history_rounded, color: AppColors.darkTextMuted, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _recentSearches.remove(item)),
                        child: const Icon(Icons.close_rounded, color: AppColors.darkTextMuted, size: 15),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 18),
          ],

          // ── 2. Explore Categories (Compact Chips) ──
          const Text(
            "Explore Categories",
            style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: exploreCategories.map((cat) {
              final (icon, name) = cat;
              return InkWell(
                onTap: () {
                  setState(() => _selectedCategory = name);
                  _searchController.text = name;
                  _onQueryChanged(name);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.darkBorderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: AppColors.communityAccent, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // ── 3. Trending Topics (Compact Chips) ──
          const Text(
            "🔥 Trending",
            style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
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
                    color: AppColors.darkSurfaceSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.darkBorderSubtle),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.communityAccent,
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
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
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
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 120,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
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

    // Filter by query and category filter
    final filtered = results.where((item) {
      final queryMatch = item['title']!.toLowerCase().contains(_query.toLowerCase()) ||
          item['subtitle']!.toLowerCase().contains(_query.toLowerCase());
      final categoryMatch = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      return queryMatch && categoryMatch;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, color: AppColors.darkTextMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                "No results found for \"$_query\"",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Try searching for another keyword or category.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12.5),
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
        final cat = res['category']!;

        IconData catIcon = Icons.article_outlined;
        if (cat == 'People') catIcon = Icons.person_outline_rounded;
        if (cat == 'Jobs') catIcon = Icons.work_outline_rounded;
        if (cat == 'Events') catIcon = Icons.event_outlined;
        if (cat == 'Communities') catIcon = Icons.groups_outlined;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.communityAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, color: AppColors.communityAccent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res['title']!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      res['subtitle']!,
                      style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cat,
                  style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
