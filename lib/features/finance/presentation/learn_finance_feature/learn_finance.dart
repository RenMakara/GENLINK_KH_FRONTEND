import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/radius/app_radius.dart';
import '../../../../design_system/shadows/app_shadows.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/loaders/app_loader.dart';
import '../../domain/entities/finance_entities.dart';
import '../controllers/finance_learning_controller.dart';
import 'investing_basics.dart';

class LearnFinanceScreen extends StatefulWidget {
  const LearnFinanceScreen({super.key});

  @override
  State<LearnFinanceScreen> createState() => _LearnFinanceScreenState();
}

class _LearnFinanceScreenState extends State<LearnFinanceScreen> {
  FinanceLearningController get controller =>
      Get.find<FinanceLearningController>();

  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearchOpen = false;
    });
  }

  void _navigateToLesson(
    BuildContext context,
    FinanceLearningLessonSummaryEntity lesson,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvestingBasicsScreen(
          lessonId: lesson.lessonId,
          initialLesson: lesson,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final dashboard = controller.dashboard.value;
          final isDashboardLoading = controller.isDashboardLoading.value;
          final dashboardError = controller.dashboardErrorMessage.value;

          final allLessons = controller.lessons.toList(growable: false);
          final isLessonsLoading = controller.isLessonsLoading.value;
          final lessonsError = controller.lessonsErrorMessage.value;
          final selectedTopic = controller.selectedTopic.value;

          // Filter lessons by search query if present
          final filteredLessons = _searchQuery.isEmpty
              ? allLessons
              : allLessons.where((lesson) {
                  final titleMatch =
                      lesson.title.toLowerCase().contains(_searchQuery);
                  final topicMatch =
                      lesson.topic.toLowerCase().contains(_searchQuery);
                  return titleMatch || topicMatch;
                }).toList(growable: false);

          // Determine featured lesson (first uncompleted or first available)
          final FinanceLearningLessonSummaryEntity? featuredLesson =
              allLessons.isNotEmpty
                  ? allLessons.firstWhere(
                      (l) => !l.completed,
                      orElse: () => allLessons.first,
                    )
                  : null;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Top App Bar
                _LearnFinanceHeader(
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  border: border,
                  surface: surface,
                  isSearchOpen: _isSearchOpen,
                  onToggleSearch: () {
                    setState(() {
                      _isSearchOpen = !_isSearchOpen;
                      if (!_isSearchOpen) {
                        _searchController.clear();
                        _searchQuery = '';
                      }
                    });
                  },
                ),

                // Expandable Search Bar
                if (_isSearchOpen) ...[
                  const SizedBox(height: 12),
                  _SearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ],

                const SizedBox(height: 16),

                // Hero Educational Banner
                _HeroBanner(
                  isDark: isDark,
                  textPrimary: textPrimary,
                  onContinueTap: () {
                    if (featuredLesson != null) {
                      _navigateToLesson(context, featuredLesson);
                    }
                  },
                ),

                const SizedBox(height: 18),

                // Progress Dashboard Card
                _ProgressCard(
                  dashboard: dashboard,
                  loading: isDashboardLoading,
                  error: dashboardError,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isDark: isDark,
                  onRetry: controller.loadDashboard,
                ),

                const SizedBox(height: 22),

                // Topics Section
                _TopicsSection(
                  topics: dashboard?.topics ?? const [],
                  selectedTopic: selectedTopic,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isDark: isDark,
                  onTopicSelected: controller.selectTopic,
                  onSeeAll: () => controller.selectTopic(null),
                ),

                // Featured for You Section (if available and not searching)
                if (featuredLesson != null && _searchQuery.isEmpty) ...[
                  const SizedBox(height: 22),
                  _FeaturedSection(
                    lesson: featuredLesson,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                    onTap: () => _navigateToLesson(context, featuredLesson),
                  ),
                ],

                const SizedBox(height: 22),

                // Lessons Section Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'finance.learning.lessons'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (filteredLessons.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filteredLessons.length}',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Lessons List
                if (isLessonsLoading && allLessons.isEmpty)
                  const SizedBox(height: 160, child: AppLoader())
                else if (lessonsError != null && allLessons.isEmpty)
                  _ErrorCard(
                    message: lessonsError,
                    onRetry: () => controller.loadLessons(),
                  )
                else if (filteredLessons.isEmpty)
                  _EmptyLessonsCard(
                    isDark: isDark,
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  )
                else
                  ...filteredLessons.map(
                    (lesson) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ModernLessonCard(
                        lesson: lesson,
                        surface: surface,
                        border: border,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                        isDark: isDark,
                        onTap: () => _navigateToLesson(context, lesson),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Motivation Bottom Banner
                _MotivationBanner(
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Top Header ───────────────────────────────────────────────────────────────
class _LearnFinanceHeader extends StatelessWidget {
  const _LearnFinanceHeader({
    required this.textPrimary,
    required this.textMuted,
    required this.border,
    required this.surface,
    required this.isSearchOpen,
    required this.onToggleSearch,
  });

  final Color textPrimary;
  final Color textMuted;
  final Color border;
  final Color surface;
  final bool isSearchOpen;
  final VoidCallback onToggleSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppBackButton(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'finance.learning.title'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'finance.learning.subtitle'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: isSearchOpen
              ? AppColors.financeAccent.withValues(alpha: 0.15)
              : surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onToggleSearch,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSearchOpen ? AppColors.financeAccent : border,
                ),
              ),
              child: Icon(
                isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: isSearchOpen ? AppColors.financeAccent : textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Search Input ─────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: textMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'finance.learning.searchPlaceholder'.tr,
                hintStyle: TextStyle(color: textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.cancel_rounded, color: textMuted, size: 18),
            ),
        ],
      ),
    );
  }
}

// ── Hero Educational Banner ─────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.isDark,
    required this.textPrimary,
    required this.onContinueTap,
  });

  final bool isDark;
  final Color textPrimary;
  final VoidCallback onContinueTap;

  @override
  Widget build(BuildContext context) {
    // Light & Dark themed gradients
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2B1D),
              Color(0xFF0B1F16),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFD1E7DD),
            ],
          );

    final borderColor = isDark
        ? const Color(0xFF1E4632)
        : const Color(0xFFB7DFC6);

    final titleColor = isDark
        ? const Color(0xFFF1F8F4)
        : const Color(0xFF0D3320);

    final subtitleColor = isDark
        ? const Color(0xFFA7D5BD)
        : const Color(0xFF26593F);

    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(AppRadius.squircle),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text & Action Column
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'finance.learning.heroTitle'.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'finance.learning.heroSubtitle'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                // Continue Learning pill CTA
                Material(
                  color: isDark ? const Color(0xFF22C55E) : const Color(0xFF0D3320),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onContinueTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'finance.learning.continueLearning'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 3D-styled Educational Illustration
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: _HeroGraphic(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero 3D Graphic ──────────────────────────────────────────────────────────
class _HeroGraphic extends StatelessWidget {
  const _HeroGraphic({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background aura glow
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                  : const Color(0xFF4BAE73).withValues(alpha: 0.2),
            ),
          ),

          // Central Book & Sprout Vector Illustration
          Positioned(
            bottom: 4,
            child: Container(
              width: 76,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1E523A), const Color(0xFF133626)]
                      : [const Color(0xFF4BAE73), const Color(0xFF2D7B4D)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 36,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ],
              ),
            ),
          ),

          // Floating Lightbulb Badge on top
          Positioned(
            top: 2,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFFD97706),
                size: 18,
              ),
            ),
          ),

          // Floating Mini Badge: "Better Money Happier You"
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B3D2B)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                    ? const Color(0xFF2D6A4F)
                    : const Color(0xFFB7DFC6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'finance.learning.betterMoney'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFA7D5BD)
                      : const Color(0xFF1E523A),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Dashboard Card ──────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.dashboard,
    required this.loading,
    required this.error,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
    required this.onRetry,
  });

  final FinanceLearningDashboardEntity? dashboard;
  final bool loading;
  final String? error;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && dashboard == null) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border: Border.all(color: border),
        ),
        child: const AppLoader(),
      );
    }
    if (error != null && dashboard == null) {
      return _ErrorCard(message: error!, onRetry: onRetry);
    }

    final total = (dashboard?.totalLessons ?? 0).clamp(0, 9999);
    final completed = (dashboard?.completedLessons ?? 0).clamp(0, total);
    final progress = total == 0 ? 0.0 : completed / total;
    final literacyXp = dashboard?.literacyXp ?? 0;
    final badgesCount = completed > 0 ? (completed / 2).ceil() : 0;
    final streakDays = completed > 0 ? 1 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.squircle),
        border: Border.all(color: border),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Your Progress" & "0/6"
          Row(
            children: [
              Expanded(
                child: Text(
                  'finance.learning.progress'.tr,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completed/$total',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Rounded Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle: "0 of 6 lessons completed"
          Text(
            'finance.learning.lessonsCompleted'.trParams({
              'completed': '$completed',
              'total': '$total',
            }),
            style: TextStyle(color: textMuted, fontSize: 12),
          ),

          const SizedBox(height: 14),

          // 3 Statistics Tiles Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                // XP earned
                Expanded(
                  child: _StatTile(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFEF3C7),
                    value: '$literacyXp',
                    label: 'finance.learning.xpEarned'.tr,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ),
                _statDivider(border),
                // Badges
                Expanded(
                  child: _StatTile(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFF97316),
                    iconBg: const Color(0xFFFFEDD5),
                    value: '$badgesCount',
                    label: 'finance.learning.badges'.tr,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ),
                _statDivider(border),
                // Day streak
                Expanded(
                  child: _StatTile(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFDBEAFE),
                    value: '$streakDays',
                    label: 'finance.learning.dayStreak'.tr,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(Color border) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: border.withValues(alpha: 0.6),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.textPrimary,
    required this.textMuted,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Topics Section ──────────────────────────────────────────────────────────
class _TopicsSection extends StatelessWidget {
  const _TopicsSection({
    required this.topics,
    required this.selectedTopic,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
    required this.onTopicSelected,
    required this.onSeeAll,
  });

  final List<FinanceLearningTopicProgressEntity> topics;
  final String? selectedTopic;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;
  final ValueChanged<String?> onTopicSelected;
  final VoidCallback onSeeAll;

  // Curated topic data if dashboard topics are empty
  static const List<String> defaultTopics = [
    'SAVING_MONEY',
    'BUDGETING',
    'DEBT_AWARENESS',
    'INVESTING_BASICS',
    'EMERGENCY_FUND',
    'SMART_SPENDING',
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveTopics = topics.isNotEmpty
        ? topics.map((t) => t.topic).toList()
        : defaultTopics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'finance.learning.topics'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'finance.learning.seeAll'.tr,
                style: const TextStyle(
                  color: AppColors.brandPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: effectiveTopics.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final topicKey = effectiveTopics[index];
              final isSelected = selectedTopic == topicKey;
              final config = _topicConfig(topicKey);

              return _TopicSquircleCard(
                topicKey: topicKey,
                label: _topicLabel(topicKey),
                icon: config.icon,
                accentColor: config.color,
                isSelected: isSelected,
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
                isDark: isDark,
                onTap: () {
                  if (isSelected) {
                    onTopicSelected(null);
                  } else {
                    onTopicSelected(topicKey);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _topicLabel(String topic) {
    final key = 'finance.learning.topic.$topic';
    final translated = key.tr;
    return translated == key ? topic : translated;
  }

  _TopicMeta _topicConfig(String topic) {
    switch (topic.toUpperCase()) {
      case 'SAVING_MONEY':
        return const _TopicMeta(
          icon: Icons.savings_rounded,
          color: Color(0xFF22C55E),
        );
      case 'BUDGETING':
        return const _TopicMeta(
          icon: Icons.query_stats_rounded,
          color: Color(0xFF8B5CF6),
        );
      case 'DEBT_AWARENESS':
        return const _TopicMeta(
          icon: Icons.credit_card_rounded,
          color: Color(0xFFEF4444),
        );
      case 'INVESTING_BASICS':
        return const _TopicMeta(
          icon: Icons.trending_up_rounded,
          color: Color(0xFF3B82F6),
        );
      case 'EMERGENCY_FUND':
        return const _TopicMeta(
          icon: Icons.shield_rounded,
          color: Color(0xFF14B8A6),
        );
      case 'SMART_SPENDING':
      default:
        return const _TopicMeta(
          icon: Icons.shopping_bag_rounded,
          color: Color(0xFFF59E0B),
        );
    }
  }
}

class _TopicMeta {
  const _TopicMeta({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

class _TopicSquircleCard extends StatelessWidget {
  const _TopicSquircleCard({
    required this.topicKey,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
    required this.onTap,
  });

  final String topicKey;
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            // Squircle Icon Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: isDark ? 0.28 : 0.16)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : accentColor.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : (isDark
                          ? border
                          : accentColor.withValues(alpha: 0.2)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? (isDark ? Colors.white : accentColor)
                    : (isDark ? accentColor.withValues(alpha: 0.85) : accentColor),
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            // Topic Name
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? textPrimary : textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured Section ─────────────────────────────────────────────────────────
class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({
    required this.lesson,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
    required this.onTap,
  });

  final FinanceLearningLessonSummaryEntity lesson;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'finance.learning.featuredForYou'.tr,
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.squircle),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.squircle),
                border: Border.all(color: border),
                boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
              ),
              child: Row(
                children: [
                  // Vector plant thumbnail
                  _PlantThumbnail(isDark: isDark),

                  const SizedBox(width: 14),

                  // Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // POPULAR Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'finance.learning.popular'.tr,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lesson.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Metadata row
                        Row(
                          children: [
                            _lessonTypeIcon(lesson.contentType, textMuted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${lesson.contentType} · ${lesson.xpReward} XP · ${lesson.estimatedTime ?? 5} ${'finance.learning.min'.tr}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons.chevron_right_rounded,
                    color: textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Plant / Coin Jar Vector Thumbnail ───────────────────────────────────────
class _PlantThumbnail extends StatelessWidget {
  const _PlantThumbnail({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF143825), Color(0xFF0D2418)]
              : const [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF1E5238) : const Color(0xFF6EE7B7),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Coin base
          Positioned(
            bottom: 12,
            child: Container(
              width: 32,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          // Sprouting Leaf
          const Positioned(
            top: 10,
            child: Icon(
              Icons.spa_rounded,
              size: 32,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modern Lesson Card ───────────────────────────────────────────────────────
class _ModernLessonCard extends StatelessWidget {
  const _ModernLessonCard({
    required this.lesson,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
    required this.onTap,
  });

  final FinanceLearningLessonSummaryEntity lesson;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeConfig = _lessonCardTypeConfig(lesson.contentType, lesson.completed);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: lesson.completed
                  ? const Color(0xFF22C55E).withValues(alpha: 0.35)
                  : border,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
          ),
          child: Row(
            children: [
              // Squircle Type Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeConfig.bgColor(isDark),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: typeConfig.borderColor(isDark),
                  ),
                ),
                child: Icon(
                  typeConfig.icon,
                  color: typeConfig.iconColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _lessonTypeIcon(lesson.contentType, textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${lesson.contentType} · ${lesson.xpReward} XP · ${lesson.estimatedTime ?? 5} ${'finance.learning.min'.tr}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _LessonCardConfig _lessonCardTypeConfig(String type, bool completed) {
    if (completed) {
      return _LessonCardConfig(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF22C55E),
        bgColor: (isDark) => const Color(0xFF22C55E).withValues(alpha: 0.15),
        borderColor: (isDark) => const Color(0xFF22C55E).withValues(alpha: 0.3),
      );
    }
    switch (type.toUpperCase()) {
      case 'VIDEO':
        return _LessonCardConfig(
          icon: Icons.play_arrow_rounded,
          iconColor: const Color(0xFFF59E0B),
          bgColor: (isDark) => const Color(0xFFF59E0B).withValues(alpha: 0.15),
          borderColor: (isDark) => const Color(0xFFF59E0B).withValues(alpha: 0.25),
        );
      case 'KHMER_TIP':
        return _LessonCardConfig(
          icon: Icons.description_rounded,
          iconColor: const Color(0xFF8B5CF6),
          bgColor: (isDark) => const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          borderColor: (isDark) => const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        );
      case 'ARTICLE':
      default:
        return _LessonCardConfig(
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF10B981),
          bgColor: (isDark) => const Color(0xFF10B981).withValues(alpha: 0.15),
          borderColor: (isDark) => const Color(0xFF10B981).withValues(alpha: 0.25),
        );
    }
  }
}

class _LessonCardConfig {
  const _LessonCardConfig({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color Function(bool isDark) bgColor;
  final Color Function(bool isDark) borderColor;
}

Widget _lessonTypeIcon(String contentType, Color muted) {
  switch (contentType.toUpperCase()) {
    case 'VIDEO':
      return Icon(Icons.videocam_outlined, size: 14, color: muted);
    case 'KHMER_TIP':
      return Icon(Icons.lightbulb_outline_rounded, size: 14, color: muted);
    case 'ARTICLE':
    default:
      return Icon(Icons.article_outlined, size: 14, color: muted);
  }
}

// ── Motivation Bottom Banner ─────────────────────────────────────────────────
class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner({
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F261B)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppRadius.squircle),
        border: Border.all(
          color: isDark ? const Color(0xFF1B4332) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1B4332)
                  : const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'finance.learning.motivationTitle'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'finance.learning.motivationSubtitle'.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: textMuted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────
class _EmptyLessonsCard extends StatelessWidget {
  const _EmptyLessonsCard({
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              'finance.learning.noLessons'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Card ───────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('common.retry'.tr),
          ),
        ],
      ),
    );
  }
}
