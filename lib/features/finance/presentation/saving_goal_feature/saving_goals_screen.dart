import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'saving_goals_create.dart';
import 'saving_goals_detail.dart';

class SavingGoalsScreen extends GetView<SavingGoalController> {
  const SavingGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final goals = controller.goals.toList(growable: false);
          final error = controller.listErrorMessage.value;
          final loading = controller.isInitialLoading.value;
          final currency = controller.selectedCurrency.value;

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              children: [
                // Top App Bar
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'finance.goal.title'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ) ?? TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'finance.savingGoals.subtitle'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w500,
                            ) ?? TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateGoalScreen(),
                          ),
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.add_rounded,
                            color: isDark
                                ? AppColors.darkTextInverse
                                : AppColors.lightTextInverse,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Currency Pill Toggle
                _CurrencyBar(
                  currency: currency,
                  onChanged: controller.selectCurrency,
                  surface: surface,
                  border: border,
                  text: textPrimary,
                  primary: primary,
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                _StatusBar(
                  value: controller.selectedStatus.value,
                  onChanged: controller.selectStatus,
                  surface: surface,
                  border: border,
                  text: textPrimary,
                  muted: muted,
                  primary: primary,
                ),
                const SizedBox(height: 18),

                // Content States
                if (loading && goals.isEmpty)
                  const SizedBox(height: 320, child: AppLoader())
                else if (error != null && goals.isEmpty)
                  SizedBox(
                    height: 320,
                    child: AppEmptyState(
                      message: error,
                      icon: Icons.cloud_off_outlined,
                      action: AppButton.secondary(
                        label: 'common.retry'.tr,
                        expanded: false,
                        onPressed: controller.loadGoals,
                      ),
                    ),
                  )
                else if (goals.isEmpty)
                  SizedBox(
                    height: 320,
                    child: AppEmptyState(
                      message: 'finance.goal.noGoals'.tr,
                      icon: Icons.savings_outlined,
                    ),
                  )
                else ...[
                  // Hero Total Saved Card
                  _SummaryCard(
                    goals: goals,
                    currency: currency,
                    surface: surface,
                    border: border,
                    text: textPrimary,
                    muted: muted,
                    primary: primary,
                  ),
                  const SizedBox(height: 20),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'finance.savingGoals.yourGoals'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'finance.savingGoals.newestFirst'.tr,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 16,
                            color: muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Goal Cards List
                  ...goals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GoalCard(
                        goal: goal,
                        surface: surface,
                        border: border,
                        text: textPrimary,
                        muted: muted,
                        primary: primary,
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GoalDetailScreen(goal: goal),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CurrencyBar extends StatelessWidget {
  const _CurrencyBar({
    required this.currency,
    required this.onChanged,
    required this.surface,
    required this.border,
    required this.text,
    required this.primary,
  });

  final FinanceCurrency currency;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color surface;
  final Color border;
  final Color text;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isUsd = currency == FinanceCurrency.usd;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: isUsd ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Row(
            children: FinanceCurrency.values.map((value) {
              final selected = value == currency;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(value),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      child: Text(value.apiValue),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.value,
    required this.onChanged,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...SavingGoalController.statuses];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((status) {
          final selected = status == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected ? primary : surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? primary : border,
                  ),
                ),
                child: Text(
                  _label(status),
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(String? status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'finance.goal.inProgress'.tr;
      case 'COMPLETED':
        return 'finance.goal.completed'.tr;
      case 'CANCELLED':
        return 'finance.goal.cancelled'.tr;
      default:
        return 'finance.goal.allStatuses'.tr;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.goals,
    required this.currency,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
  });

  final List<FinanceSavingGoalEntity> goals;
  final FinanceCurrency currency;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final totalCurrent = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.currentAmount,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'finance.savingGoals.fromLastMonth'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'finance.savingGoals.totalSaved'.tr,
            style: TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              FinanceMoneyFormatter.format(totalCurrent, currency),
              style: TextStyle(
                color: text,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 14,
                color: muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'finance.savingGoals.acrossGoals'.trParams({
                    'count': goals.length.toString(),
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onTap,
  });

  final FinanceSavingGoalEntity goal;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = (goal.progressPercent / 100).clamp(0.0, 1.0);
    final category = _GoalCategoryInfo.fromTitle(goal.title);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatGoalDate(goal.targetDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(status: goal.status, primary: primary),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: muted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${FinanceMoneyFormatter.format(goal.currentAmount, goal.currency)} / ${FinanceMoneyFormatter.format(goal.targetAmount, goal.currency)}',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${goal.progressPercent}%',
                  style: TextStyle(
                    color: category.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: category.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(category.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGoalDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return 'finance.savingGoals.noDeadline'.tr;
    }
    try {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        final formatted =
            '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
        return 'finance.savingGoals.dueOn'.trParams({'date': formatted});
      }
    } catch (_) {}
    return 'finance.savingGoals.dueOn'.trParams({'date': rawDate});
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.primary});

  final String status;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final completed = status == 'COMPLETED';
    final cancelled = status == 'CANCELLED';
    final color = cancelled
        ? Theme.of(context).colorScheme.error
        : completed
            ? const Color(0xFF10B981)
            : primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _statusLabel(String raw) {
    switch (raw) {
      case 'IN_PROGRESS':
        return 'finance.goal.inProgress'.tr;
      case 'COMPLETED':
        return 'finance.goal.completed'.tr;
      case 'CANCELLED':
        return 'finance.goal.cancelled'.tr;
      default:
        return raw;
    }
  }
}

class _GoalCategoryInfo {
  final IconData icon;
  final Color color;

  const _GoalCategoryInfo(this.icon, this.color);

  static _GoalCategoryInfo fromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('laptop') ||
        lower.contains('macbook') ||
        lower.contains('computer') ||
        lower.contains('phone')) {
      return const _GoalCategoryInfo(
        Icons.laptop_mac_rounded,
        Color(0xFF2563EB),
      );
    }
    if (lower.contains('car') ||
        lower.contains('vehicle') ||
        lower.contains('bike') ||
        lower.contains('moto')) {
      return const _GoalCategoryInfo(
        Icons.directions_car_rounded,
        Color(0xFFEF4444),
      );
    }
    if (lower.contains('travel') ||
        lower.contains('trip') ||
        lower.contains('japan') ||
        lower.contains('flight') ||
        lower.contains('vacation')) {
      return const _GoalCategoryInfo(
        Icons.flight_rounded,
        Color(0xFF8B5CF6),
      );
    }
    if (lower.contains('emergency') ||
        lower.contains('fund') ||
        lower.contains('health') ||
        lower.contains('shield')) {
      return const _GoalCategoryInfo(
        Icons.shield_outlined,
        Color(0xFF10B981),
      );
    }
    return const _GoalCategoryInfo(
      Icons.savings_outlined,
      Color(0xFFF59E0B),
    );
  }
}
