import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/saving_goal_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'saving_goals_create.dart';
import 'saving_goals_detail.dart';

/// Currency- and status-scoped list of the user's backend saving goals.
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
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
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
                Row(
                  children: [
                    AppBackButton(),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'finance.goal.title'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateGoalScreen(),
                        ),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: isDark
                            ? AppColors.darkTextInverse
                            : AppColors.lightTextInverse,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CurrencyBar(
                  currency: currency,
                  onChanged: controller.selectCurrency,
                  surface: surface,
                  border: border,
                  text: text,
                  primary: primary,
                ),
                const SizedBox(height: 10),
                _StatusBar(
                  value: controller.selectedStatus.value,
                  onChanged: controller.selectStatus,
                  surface: surface,
                  border: border,
                  text: text,
                  muted: muted,
                  primary: primary,
                ),
                const SizedBox(height: 18),
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
                  _SummaryCard(
                    goals: goals,
                    currency: currency,
                    surface: surface,
                    border: border,
                    text: text,
                    muted: muted,
                    primary: primary,
                  ),
                  const SizedBox(height: 14),
                  ...goals.map(
                    (goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GoalCard(
                        goal: goal,
                        surface: surface,
                        border: border,
                        text: text,
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
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Stack(
        children: [
          // Sliding background
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: isUsd ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Currency buttons
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
      child: Row(
        children: options.map((status) {
          final selected = status == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(status)),
              selected: selected,
              onSelected: (_) => onChanged(status),
              backgroundColor: surface,
              selectedColor: primary,
              side: BorderSide(color: border),
              labelStyle: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : muted,
                fontWeight: FontWeight.w600,
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
    final active = goals.where((goal) => goal.status == 'IN_PROGRESS').length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, color: primary, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('finance.goal.current'.tr, style: TextStyle(color: muted)),
                const SizedBox(height: 3),
                Text(
                  FinanceMoneyFormatter.format(totalCurrent, currency),
                  style: TextStyle(
                    color: text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$active ${'finance.goal.inProgress'.tr.toLowerCase()}',
            textAlign: TextAlign.end,
            style: TextStyle(color: muted, fontSize: 12),
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
                Expanded(
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusPill(status: goal.status, primary: primary),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: primary.withValues(alpha: 0.12),
                color: primary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${FinanceMoneyFormatter.format(goal.currentAmount, goal.currency)} / ${FinanceMoneyFormatter.format(goal.targetAmount, goal.currency)}',
                    style: TextStyle(color: text, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${goal.progressPercent}%',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (goal.targetDate != null) ...[
              const SizedBox(height: 6),
              Text(
                '${'finance.goal.deadline'.tr}: ${goal.targetDate}',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
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
        ? Colors.green
        : primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
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
