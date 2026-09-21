import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../domain/entities/productivity_entities.dart';
import '../controllers/productivity_controller.dart';
import '../productivity_scope.dart';
import '../widgets/productivity_illustrations.dart';
import '../widgets/productivity_list_components.dart';
import 'goal_plan_create.dart';
import 'goal_plan_detail.dart';

class PlanGoalScreen extends StatefulWidget {
  const PlanGoalScreen({super.key});

  @override
  State<PlanGoalScreen> createState() => _PlanGoalScreenState();
}

class _PlanGoalScreenState extends State<PlanGoalScreen> {
  ProductivityController? _controller;
  String _category = 'All';

  static const _categories = ['All', 'Personal', 'Career', 'Skill', 'Finance'];

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  Future<void> _createGoal() async {
    await Get.to(() => const CreateGoalScreen());
    await _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const _UnavailableGoalsView();

    final colors = ListThemeColors(context);
    return Obx(() {
      if (controller.isLoading.value && controller.goals.isEmpty) {
        return Scaffold(
          backgroundColor: colors.background,
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final goals = controller.goals
          .where((goal) {
            if (_category == 'All') return true;
            return goal.goalType?.toUpperCase() == _category.toUpperCase();
          })
          .toList(growable: false);

      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.reload,
            color: AppColors.productivityAccent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 36),
              children: [
                // Top Header (Back, Title, Subtitle, + Button)
                ListScreenHeader(
                  title: 'goals.title'.tr,
                  subtitle: 'goals.subtitle'.tr,
                  onAdd: _createGoal,
                  addTooltip: 'goals.createGoal'.tr,
                ),

                // Hero Banner (Mint gradient with 3D Target & Dart)
                ListHeroBanner(
                  illustration: const Soft3DTargetDartboardWidget(size: 68),
                  title: 'goals.heroQuote'.tr,
                  subtitle: 'goals.heroSub'.tr,
                  gradientColors: const [Color(0xFFE8FDF0), Color(0xFFD1FAE5)],
                  titleColor: const Color(0xFF065F46),
                  subtitleColor: const Color(0xFF047857),
                  shadowColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 10),

                // Category Filter Pills
                PillFilterTabs<String>(
                  selected: _category,
                  options: _categories,
                  labelBuilder: (category) =>
                      category == 'All' ? 'tasks.filter.all'.tr : category,
                  onChanged: (cat) => setState(() => _category = cat),
                  accentColor: const Color(0xFF8B5CF6),
                ),

                // Section Header (My goals + Count)
                ListSectionHeader(
                  title: 'goals.myGoals'.tr,
                  countText: '${goals.length}',
                ),

                // Goals List or Empty State
                if (goals.isEmpty)
                  ListEncouragementCard(
                    illustration: const Soft3DGoalMoundWidget(
                      width: 84,
                      height: 62,
                    ),
                    title: 'goals.emptyTitle'.tr,
                    subtitle: 'goals.emptySubtitle'.tr,
                    buttonLabel: 'goals.createGoal'.tr,
                    onAction: _createGoal,
                  )
                else
                  ...goals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      child: _GoalTile(
                        goal: goal,
                        onTap: () async {
                          await Get.to(() => GoalDetailScreen(goal: goal));
                          await controller.reload();
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Bottom Motivation / Tip Card (Lightbulb + Chevron)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _GoalTipCard(
                    onTap: _createGoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.onTap});

  final ProductivityGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);
    final isDark = colors.isDark;
    final progress = (goal.progressPercentage / 100).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Pill Badge + Progress Percent
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (goal.goalType ?? 'PERSONAL').toUpperCase(),
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF15803D),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Text(
                    '${goal.progressPercentage.round()}%',
                    style: TextStyle(
                      color: const Color(0xFF22C55E),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                goal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              // Green Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: const Color(0xFF22C55E),
                  backgroundColor: colors.surfaceSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // Footer: Status / Milestone info + Deadline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _statusLabel(goal.status),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (goal.deadline != null)
                    Text(
                      'goals.due'.trParams({'date': _formatDate(goal.deadline!)}),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11.5,
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

class _GoalTipCard extends StatelessWidget {
  const _GoalTipCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ListThemeColors(context);
    final isDark = colors.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.22)
                : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF047857).withValues(alpha: 0.35)
                  : const Color(0xFFDCFCE7),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Lightbulb Icon Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF78350F).withValues(alpha: 0.40)
                      : const Color(0xFFFEF3C7),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'goals.tipTitle'.tr,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'goals.tipSubtitle'.tr,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.70)
                            : const Color(0xFF059669),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Circular Chevron Right
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFFD1FAE5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white : const Color(0xFF059669),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableGoalsView extends StatelessWidget {
  const _UnavailableGoalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('goals.signInToManage'.tr)),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'COMPLETED' => 'goals.statusCompleted'.tr,
  'IN_PROGRESS' => 'goals.statusInProgress'.tr,
  _ => 'goals.statusNotStarted'.tr,
};

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Kept for compatibility with older callers of the original mock screens.
class GoalModel {
  GoalModel({
    required this.category,
    required this.title,
    required this.progress,
    required this.dueDate,
  });

  final String category;
  final String title;
  final double progress;
  final String dueDate;
}
