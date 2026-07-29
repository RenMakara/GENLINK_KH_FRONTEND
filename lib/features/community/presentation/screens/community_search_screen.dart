import 'package:flutter/material.dart';
import '../../../../design_system/colors/app_colors.dart';
import '../widgets/filter_events_sheet.dart';

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
  late String _selectedSubFilter;
  bool _isLoading = false;

  final List<String> _recentSearches = [
    'Flutter Workshop 2026',
    'ABA Bank Internship',
    'Riverpod State Management',
    'Campus Hackathon',
  ];

  late List<String> _subFilters;

  @override
  void initState() {
    super.initState();
    _subFilters = _getSubFiltersForTab(widget.activeTab);
    _selectedSubFilter = _subFilters.first;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<String> _getSubFiltersForTab(String tab) {
    switch (tab) {
      case 'Forum':
        return ['Discussions', 'Categories', 'Trending'];
      case 'Career':
        return ['Jobs', 'Companies', 'Skills', 'Mentors'];
      case 'Event':
        return ['Events', 'Workshops', 'Competitions', 'Seminars'];
      case 'Feed':
      default:
        return ['Posts', 'People', 'Communities', 'Topics'];
    }
  }

  String _getHintText() {
    switch (widget.activeTab) {
      case 'Forum':
        return 'Search discussions & topics...';
      case 'Career':
        return 'Search jobs, internships & mentors...';
      case 'Event':
        return 'Search events, workshops & hackathons...';
      case 'Feed':
      default:
        return 'Search posts, people & communities...';
    }
  }

  void _onQueryChanged(String text) {
    setState(() {
      _query = text;
      _isLoading = text.trim().isNotEmpty;
    });

    if (text.trim().isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _clearRecentSearches() {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.darkTextMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    hintText: _getHintText(),
                    hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _searchController.clear();
                    _onQueryChanged('');
                  },
                ),
            ],
          ),
        ),
        actions: [
          if (widget.activeTab == 'Event')
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.communityAccent, size: 22),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const FilterEventsSheet(),
                );
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Context-Aware Sub-Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _subFilters.map((filter) {
                final isSelected = _selectedSubFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSubFilter = filter;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.communityAccent
                            : AppColors.darkSurfaceSecondary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.communityAccent : AppColors.darkBorderSubtle,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.darkTextSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic Body Content (Querying or Idle)
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
  // Idle State: Recent Searches & Trending Searches
  // ---------------------------------------------------------------------------
  Widget _buildIdleState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Searches",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: const Text("Clear All", style: TextStyle(color: AppColors.communityAccent, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ..._recentSearches.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded, color: AppColors.darkTextMuted, size: 20),
                title: Text(item, style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.darkTextMuted, size: 18),
                  onPressed: () {
                    setState(() {
                      _recentSearches.remove(item);
                    });
                  },
                ),
                onTap: () {
                  _searchController.text = item;
                  _onQueryChanged(item);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Text(
            "🔥 Trending Searches",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              '#FlutterTech',
              'ABA Bank Internship',
              'GenLink Hackathon 2026',
              'Riverpod Tutorial',
              'CADT Campus Expo',
              'Senior Dev Mentors',
            ].map((trend) {
              return InkWell(
                onTap: () {
                  _searchController.text = trend;
                  _onQueryChanged(trend);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, color: AppColors.communityAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(trend, style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading State
  // ---------------------------------------------------------------------------
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.communityAccent),
    );
  }

  // ---------------------------------------------------------------------------
  // Search Results
  // ---------------------------------------------------------------------------
  Widget _buildSearchResults() {
    final List<Map<String, String>> results = [
      {
        'title': 'Flutter Workshop 2026 @ ACLEDA',
        'subtitle': 'Learn cross-platform mobile development with Riverpod & Material 3.',
        'tag': widget.activeTab,
      },
      {
        'title': 'Junior Flutter Developer - ABA Bank',
        'subtitle': 'Full-time position in Phnom Penh • \$600 - \$900/mo',
        'tag': 'Career',
      },
      {
        'title': 'Best practices for Clean Architecture in Flutter',
        'subtitle': 'Discussion by Sokchea Lim • 34 comments',
        'tag': 'Forum',
      },
    ].where((res) => res['title']!.toLowerCase().contains(_query.toLowerCase()) || res['subtitle']!.toLowerCase().contains(_query.toLowerCase())).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, color: AppColors.darkTextMuted, size: 56),
            const SizedBox(height: 12),
            Text(
              "No results found for \"$_query\"",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Try searching for another keyword or topic.",
              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final res = results[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.darkBorderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.communityAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search_rounded, color: AppColors.communityAccent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(res['subtitle']!, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
