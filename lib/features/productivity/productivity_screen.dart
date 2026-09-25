import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../design_system/colors/app_colors.dart';
import 'domain/entities/productivity_entities.dart';
import 'presentation/controllers/productivity_controller.dart';
import 'presentation/goals_plan/goal_plan.dart';
import 'presentation/productivity_scope.dart';
import 'presentation/task_feature/task_home_screen.dart';
import 'presentation/widgets/productivity_components.dart';

class ProductivityPage extends StatefulWidget {
  const ProductivityPage({super.key});

  @override
  State<ProductivityPage> createState() => _ProductivityPageState();
}

class _ProductivityPageState extends State<ProductivityPage> {
  ProductivityController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = ensureProductivityController();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const _UnavailableView();

    return Obx(() {
      final dashboard = controller.dashboard.value;
      if (controller.isLoading.value && dashboard == null) {
        return const _LoadingView();
      }
      if (dashboard == null) {
        return _ErrorView(
          message:
              controller.errorMessage.value ??
              'Unable to load productivity data.',
          onRetry: controller.load,
        );
      }
      return _DashboardView(controller: controller, dashboard: dashboard);
    });
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.controller, required this.dashboard});

  final ProductivityController controller;
  final ProductivityDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final colors = _ProductivityColors(context);
    final completedTasks = dashboard.tasks.completed;
    final totalTasks = dashboard.tasks.total;
    final habitStreak = controller.habits.isEmpty
        ? null
        : controller.habits
              .map((habit) => habit.streakCount)
              .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.reload,
          color: AppColors.productivityAccent,
          backgroundColor: colors.surface,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
            children: [
              ProductivityHeader(
                streakCount: habitStreak,
                onNotifications: () => Get.toNamed(AppRoutes.notifications),
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 18),
              ProductivitySummaryCard(
                completedTasks: completedTasks,
                totalTasks: totalTasks,
                focusMinutes: dashboard.focus.todayMinutes,
                habitStreak: habitStreak,
              ),
              const SizedBox(height: 20),
              ProductivityTodayPlan(
                controller: controller,
                onSeeAll: () => Get.to(() => const TasksPage()),
              ),
              const SizedBox(height: 20),
              ProductivityQuickActions(
                controller: controller,
              ),
              const SizedBox(height: 20),
              ProductivityGoalProgressSection(
                goals: dashboard.goals,
                onSeeAll: () => Get.to(() => const PlanGoalScreen()),
              ),
              if (dashboard.motivation != null) ...[
                const SizedBox(height: 20),
                ProductivityMotivationSection(
                  motivation: dashboard.motivation!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: Text('common.retry'.tr)),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(child: Text('productivity.availableAfterSignIn'.tr)),
    );
  }
}

class _ProductivityColors {
  _ProductivityColors(BuildContext context)
    : isDark = Theme.of(context).brightness == Brightness.dark;

  final bool isDark;

  Color get background =>
      isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
  Color get surface =>
      isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
  Color get surfaceSecondary =>
      isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textMuted =>
      isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get border =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
}
