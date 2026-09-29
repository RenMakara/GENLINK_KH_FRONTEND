import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../design_system/colors/app_colors.dart';
import '../../../../design_system/spacing/app_spacing.dart';
import '../../../../design_system/widgets/buttons/app_back_button.dart';
import '../../../../design_system/widgets/dialogs/genlink_confirm_dialog.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/entities/finance_money.dart';
import '../controllers/finance_controller.dart';
import '../controllers/finance_tools_controller.dart';
import '../formatters/finance_money_formatter.dart';
import '../widgets/finance_currency_selector.dart';
import '../widgets/finance_insights_widgets.dart';
import '../expense_feature/expense_screen.dart';
import '../income_feature/income_screen.dart';
import '../learn_finance_feature/investing_basics.dart';
import '../learn_finance_feature/learn_finance.dart';
import '../saving_goal_feature/saving_goals_screen.dart';

// ============================================================================
// FINANCE TOOLS MAIN SCREEN
// ============================================================================

class FinanceToolsScreen extends GetView<FinanceToolsController> {
  const FinanceToolsScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex.clamp(0, 2),
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          leading: const Center(child: AppBackButton()),
          leadingWidth: 64,
          titleSpacing: 0,
          title: Text(
            'finance.tools.title'.tr,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          actions: [
            Builder(
              builder: (context) {
                final tabController = DefaultTabController.of(context);
                return AnimatedBuilder(
                  animation: tabController,
                  builder: (context, _) {
                    if (tabController.index == 0) {
                      return const SizedBox.shrink();
                    }
                    final isRecurring = tabController.index == 1;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brandPrimary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandPrimary.withValues(alpha: 0.32),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Tooltip(
                            message: isRecurring
                                ? 'finance.tools.createRecurring'.tr
                                : 'finance.tools.createAutoSave'.tr,
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                key: const Key('finance_tools_add_button'),
                                customBorder: const CircleBorder(),
                                onTap: () => isRecurring
                                    ? _showRecurringForm(context, controller)
                                    : _showAutoSaveForm(context, controller),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(54),
            child: _FinanceToolsTabBar(),
          ),
        ),
        body: TabBarView(
          children: [
            _InsightsTab(controller: controller),
            _RecurringTab(controller: controller),
            _AutoSaveTab(controller: controller),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB BAR (Matching reference: soft blue pill + active underline bar)
// ============================================================================

class _FinanceToolsTabBar extends StatelessWidget {
  const _FinanceToolsTabBar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabController = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final activeIndex = tabController.index;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'finance.tools.insights'.tr,
                      isSelected: activeIndex == 0,
                      isDark: isDark,
                      onTap: () => tabController.animateTo(0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'finance.tools.recurring'.tr,
                      isSelected: activeIndex == 1,
                      isDark: isDark,
                      onTap: () => tabController.animateTo(1),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'finance.tools.autoSave'.tr,
                      isSelected: activeIndex == 2,
                      isDark: isDark,
                      onTap: () => tabController.animateTo(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 0.8,
              color: colors.outlineVariant.withValues(alpha: 0.35),
            ),
          ],
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final activeFg = AppColors.brandPrimary;
    final inactiveFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? activeFg : inactiveFg,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 3,
            width: 52,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 1. INSIGHTS TAB (Matching Reference Screen 1)
// ============================================================================

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({required this.controller});
  final FinanceToolsController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final finance = Get.find<FinanceController>();
    final data = finance.financeInsights.value;
    final currency = controller.insightsCurrency.value;
    final month = controller.insightsMonth.value;
    final year = controller.insightsYear.value;
    final matches =
        data?.currency == currency &&
        data?.month == month &&
        data?.year == year;

    return RefreshIndicator(
      onRefresh: controller.loadInsights,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Currency + Month Controls Row
          _InsightsPeriodControls(
            currency: currency,
            month: month,
            year: year,
            controller: controller,
          ),
          const SizedBox(height: AppSpacing.md),

          if (!matches && finance.isInsightsLoading.value)
            const _LoadingState()
          else if (!matches && finance.insightsErrorMessage.value != null)
            _FinanceErrorState(
              message: finance.insightsErrorMessage.value!,
              onRetry: controller.loadInsights,
            )
          else if (matches) ...[
            // Main Net Cash Flow Card
            _NetCashFlowCard(
              amount: data!.net,
              currency: currency,
              month: month,
              year: year,
              trend: FinanceTrendBadge(
                metric: FinanceTrendMetric.net,
                currency: currency,
                month: month,
                year: year,
              ),
              previous: _previousPeriodCashFlow(finance, currency, month, year),
            ),
            const SizedBox(height: 12),

            // Two Side-by-Side Metric Cards: Income & Expenses
            Row(
              children: [
                Expanded(
                  child: _CompactMetricCard(
                    label: 'finance.insights.income'.tr,
                    amount: data.income,
                    currency: currency,
                    icon: Icons.arrow_upward_rounded,
                    accent: AppColors.success,
                    trend: FinanceTrendBadge(
                      metric: FinanceTrendMetric.income,
                      currency: currency,
                      month: month,
                      year: year,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CompactMetricCard(
                    label: 'finance.insights.expense'.tr,
                    amount: data.expense,
                    currency: currency,
                    icon: Icons.arrow_downward_rounded,
                    accent: AppColors.danger,
                    trend: FinanceTrendBadge(
                      metric: FinanceTrendMetric.expense,
                      currency: currency,
                      month: month,
                      year: year,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Savings Rate Card with Circular Donut Chart
            _SavingsRateCard(
              amount: data.savingsRatePercent,
              trend: FinanceTrendBadge(
                metric: FinanceTrendMetric.savingsRate,
                currency: currency,
                month: month,
                year: year,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Insights Section Header
            _SectionHeader(
              title: 'finance.tools.insightSection'.tr,
              actionLabel: 'finance.seeAll'.tr,
              onAction: data.insights.isNotEmpty
                  ? () => _showAllInsightsSheet(context, data.insights, currency)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),

            if (data.insights.isEmpty)
              _FinanceEmptyState(
                icon: Icons.lightbulb_outline_rounded,
                title: data.income == 0 && data.expense == 0
                    ? 'finance.insights.noData'.tr
                    : 'finance.insights.noInsight'.tr,
                description: 'finance.tools.insightEmptyNote'.tr,
              )
            else
              for (final insight in data.insights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InsightCard(insight: insight, currency: currency),
                ),
          ] else if (finance.insightsErrorMessage.value != null)
            _FinanceErrorState(
              message: finance.insightsErrorMessage.value!,
              onRetry: controller.loadInsights,
            )
          else
            const _LoadingState(),
        ],
      ),
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Insights Controls (Currency switch + Month pagination)
// ─────────────────────────────────────────────────────────────────────────────

class _InsightsPeriodControls extends StatelessWidget {
  const _InsightsPeriodControls({
    required this.currency,
    required this.month,
    required this.year,
    required this.controller,
  });

  final FinanceCurrency currency;
  final int month;
  final int year;
  final FinanceToolsController controller;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(year, month + 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Reusable USD ↔ KHR switch (GenLink existing component)
        FinanceCurrencySelector(
          selectedCurrency: currency,
          onChanged: controller.selectInsightsCurrency,
          compact: true,
        ),

        // Month Selector: <  Sep 2026  >
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'finance.tools.previousMonth'.tr,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
              ),
              iconSize: 20,
              onPressed: controller.previousInsightsMonth,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _monthLabel(month, year),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            IconButton(
              tooltip: 'finance.tools.nextMonth'.tr,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
              ),
              iconSize: 20,
              onPressed: nextMonth.isAfter(currentMonth)
                  ? null
                  : controller.nextInsightsMonth,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Net Cash Flow Card with Mini Bar Chart
// ─────────────────────────────────────────────────────────────────────────────

class _NetCashFlowCard extends StatelessWidget {
  const _NetCashFlowCard({
    required this.amount,
    required this.currency,
    required this.month,
    required this.year,
    required this.trend,
    required this.previous,
  });

  final double amount;
  final FinanceCurrency currency;
  final int month;
  final int year;
  final Widget trend;
  final FinanceCashFlowEntity? previous;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'finance.insights.net'.tr,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    FinanceMoneyFormatter.format(amount, currency),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                trend,
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Mini Gradient Bar Chart
          _MiniCashFlowBarChart(netAmount: amount),
        ],
      ),
    );
  }
}

class _MiniCashFlowBarChart extends StatelessWidget {
  const _MiniCashFlowBarChart({required this.netAmount});
  final double netAmount;

  @override
  Widget build(BuildContext context) {
    final heights = [0.35, 0.55, 0.40, 0.65, 0.95, 0.70, 0.85];

    return SizedBox(
      height: 52,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(heights.length, (index) {
          final h = heights[index] * 48;
          final isPrimary = index == 4;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 7,
              height: math.max(8.0, h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.5),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: isPrimary
                      ? [const Color(0xFF38BDF8), const Color(0xFF2563EB)]
                      : [
                          const Color(0xFFBAE6FD).withValues(alpha: 0.7),
                          const Color(0xFF60A5FA).withValues(alpha: 0.7),
                        ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact Metric Card (Income / Expenses)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.accent,
    required this.trend,
  });

  final String label;
  final double amount;
  final FinanceCurrency currency;
  final IconData icon;
  final Color accent;
  final Widget trend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Icon Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    FinanceMoneyFormatter.format(amount, currency),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 17.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 11),
                  child: trend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Savings Rate Card with Circular Donut Chart
// ─────────────────────────────────────────────────────────────────────────────

class _SavingsRateCard extends StatelessWidget {
  const _SavingsRateCard({required this.amount, required this.trend});

  final double amount;
  final Widget trend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = amount.isFinite
        ? (amount / 100).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Purple Icon Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.percent_rounded,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Label, Big Percentage, and Trend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'finance.insights.savingsRate'.tr,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${amount.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 3),
                trend,
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Circular Donut Progress Ring with Center Text (Matching Reference Screen 1)
          _SavingsDonutChart(
            progress: progress,
            label: '${amount.toStringAsFixed(1)}%',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SavingsDonutChart extends StatelessWidget {
  const _SavingsDonutChart({
    required this.progress,
    required this.label,
    required this.isDark,
  });

  final double progress;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: CustomPaint(
        painter: _SavingsDonutPainter(
          progress: progress,
          trackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          progressColor: const Color(0xFF2563EB),
          strokeWidth: 6.5,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingsDonutPainter extends CustomPainter {
  const _SavingsDonutPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Foreground progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SavingsDonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Insight Card & Detail Modals
// ─────────────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.insight,
    required this.currency,
    this.onTap,
  });

  final FinanceInsightEntity insight;
  final FinanceCurrency currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _insightColor(context, insight.severity);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () => _showInsightDetailSheet(context, insight, currency),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rounded Rectangle Icon Badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_insightIcon(insight.severity), color: accent, size: 22),
                ),
                const SizedBox(width: 12),

                // Title & Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        insight.title,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        insight.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing Chevron Button
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.5)
                        : const Color(0xFFF1F5F9),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showInsightDetailSheet(
  BuildContext context,
  FinanceInsightEntity insight,
  FinanceCurrency currency,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _InsightDetailModal(
      insight: insight,
      currency: currency,
    ),
  );
}

void _showAllInsightsSheet(
  BuildContext context,
  List<FinanceInsightEntity> insights,
  FinanceCurrency currency,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AllInsightsModal(
      insights: insights,
      currency: currency,
    ),
  );
}

class _InsightDetailModal extends StatelessWidget {
  const _InsightDetailModal({
    required this.insight,
    required this.currency,
  });

  final FinanceInsightEntity insight;
  final FinanceCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _insightColor(context, insight.severity);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final hasLesson = insight.lessonId != null && insight.lessonId!.isNotEmpty;
    final isSavings = insight.type.toUpperCase().contains('SAVING') ||
        insight.title.toLowerCase().contains('saving') ||
        insight.message.toLowerCase().contains('saving') ||
        insight.message.toLowerCase().contains('emergency fund');
    final isExpense = insight.category != null ||
        insight.type.toUpperCase().contains('EXPENSE') ||
        insight.type.toUpperCase().contains('SPENDING');
    final isIncome = insight.type.toUpperCase().contains('INCOME');

    final String actionText;
    final IconData actionIcon;
    final VoidCallback onAction;

    if (hasLesson) {
      actionText = insight.lessonTitle != null && insight.lessonTitle!.isNotEmpty
          ? 'Start: ${insight.lessonTitle!}'
          : 'finance.tools.startLesson'.tr;
      actionIcon = Icons.school_rounded;
      onAction = () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => InvestingBasicsScreen(lessonId: insight.lessonId!),
          ),
        );
      };
    } else if (isSavings) {
      actionText = 'finance.saveGoal'.tr;
      actionIcon = Icons.savings_rounded;
      onAction = () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const SavingGoalsScreen()),
        );
      };
    } else if (isExpense) {
      actionText = 'finance.insights.expense'.tr;
      actionIcon = Icons.trending_down_rounded;
      onAction = () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const ExpenseScreen()),
        );
      };
    } else if (isIncome) {
      actionText = 'finance.insights.income'.tr;
      actionIcon = Icons.trending_up_rounded;
      onAction = () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const IncomeScreen()),
        );
      };
    } else {
      actionText = 'finance.tools.exploreLessons'.tr;
      actionIcon = Icons.auto_stories_rounded;
      onAction = () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const LearnFinanceScreen()),
        );
      };
    }

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Icon badge + Severity tag + Close button
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _insightIcon(insight.severity),
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  insight.severity.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (insight.category != null && insight.category!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    insight.category!,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: subtitleColor,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            insight.title,
            style: TextStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Full, untruncated message
          Text(
            insight.message,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.55,
              color: subtitleColor,
            ),
          ),

          // Optional amount highlight
          if (insight.amount != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'finance.tools.amount'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    FinanceMoneyFormatter.format(insight.amount!, currency),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Optional Recommended Lesson box
          if (insight.lessonTitle != null && insight.lessonTitle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB)
                    .withValues(alpha: isDark ? 0.20 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'finance.tools.recommendedLesson'.tr,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          insight.lessonTitle!,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          // Primary Redirection Action Button
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 19),
            label: Text(
              actionText,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Close button
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Text(
              'common.close'.tr,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllInsightsModal extends StatelessWidget {
  const _AllInsightsModal({
    required this.insights,
    required this.currency,
  });

  final List<FinanceInsightEntity> insights;
  final FinanceCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'finance.tools.insightSection'.tr,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: subtitleColor,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: insights.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final insight = insights[index];
                return _InsightCard(
                  insight: insight,
                  currency: currency,
                  onTap: () {
                    Navigator.pop(context);
                    _showInsightDetailSheet(context, insight, currency);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. RECURRING TAB (Matching Reference Screen 2)
// ============================================================================

class _RecurringTab extends StatelessWidget {
  const _RecurringTab({required this.controller});
  final FinanceToolsController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final items = controller.recurringTransactions.toList(growable: false);
    final upcoming = items.where((item) => item.active).toList()
      ..sort((a, b) => a.nextRunDate.compareTo(b.nextRunDate));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: controller.loadRecurringTransactions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Banner Card
          _RecurringBannerCard(isDark: isDark),
          const SizedBox(height: AppSpacing.md),

          if (controller.isRecurringLoading.value && items.isEmpty)
            const _LoadingState()
          else if (controller.recurringErrorMessage.value != null &&
              items.isEmpty)
            _FinanceErrorState(
              message: controller.recurringErrorMessage.value!,
              onRetry: controller.loadRecurringTransactions,
            )
          else if (items.isEmpty)
            _FinanceEmptyState(
              icon: Icons.event_repeat_rounded,
              title: 'finance.tools.recurringEmpty'.tr,
              description: 'finance.tools.recurringEmptyNote'.tr,
              action: () => _showRecurringForm(context, controller),
            )
          else ...[
            if (controller.recurringErrorMessage.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _FinanceErrorState(
                  message: controller.recurringErrorMessage.value!,
                  onRetry: controller.loadRecurringTransactions,
                  compact: true,
                ),
              ),

            // Upcoming Section
            _SectionHeader(
              title: 'finance.tools.upcoming'.tr,
              count: upcoming.length,
              actionLabel: 'finance.seeAll'.tr,
            ),
            const SizedBox(height: AppSpacing.sm),

            if (upcoming.isEmpty)
              _InlineEmptyMessage(
                icon: Icons.calendar_today_rounded,
                message: 'finance.tools.noUpcoming'.tr,
              )
            else
              for (final item in upcoming.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecurringCard(
                    item: item,
                    controller: controller,
                    onDelete: () => _confirmDelete(
                      context,
                      'finance.tools.deleteRecurring'.tr,
                      () => controller.deleteRecurringTransaction(item.id),
                      () => controller.recurringMutationError.value,
                    ),
                  ),
                ),
            const SizedBox(height: AppSpacing.md),

            // All Recurring Section
            _SectionHeader(
              title: '${'finance.tools.allRecurring'.tr} (${items.length})',
              actionWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecurringCard(
                  item: item,
                  controller: controller,
                  onDelete: () => _confirmDelete(
                    context,
                    'finance.tools.deleteRecurring'.tr,
                    () => controller.deleteRecurringTransaction(item.id),
                    () => controller.recurringMutationError.value,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Recurring Banner Card
// ─────────────────────────────────────────────────────────────────────────────

class _RecurringBannerCard extends StatelessWidget {
  const _RecurringBannerCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? const Color(0xFF334155)
            : const Color(0xFFBFDBFE).withValues(alpha: 0.6),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_repeat_rounded,
            color: Color(0xFF2563EB),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'finance.tools.recurring'.tr,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'finance.tools.scheduledNote'.tr,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Recurring Card (Matching Reference Screen 2)
// ─────────────────────────────────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.controller,
    required this.onDelete,
  });

  final FinanceRecurringTransactionEntity item;
  final FinanceToolsController controller;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = item.type == FinanceRecurringType.income;
    final isDeleting = controller.deletingRecurringId.value == item.id;

    final badgeIcon = isIncome
        ? Icons.work_outline_rounded
        : (item.category?.toLowerCase().contains('stream') == true
            ? Icons.movie_outlined
            : Icons.home_outlined);
    final badgeColor = isIncome
        ? const Color(0xFF10B981)
        : (item.category?.toLowerCase().contains('stream') == true
            ? const Color(0xFFEF4444)
            : const Color(0xFF8B5CF6));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Category / Type Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 21),
          ),
          const SizedBox(width: 12),

          // Title, Subtitle, and Next Scheduled Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    _recurringTypeLabel(item.type),
                    if (item.category?.trim().isNotEmpty == true)
                      item.category!.trim(),
                    _frequencyLabel(item.frequency),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${'finance.tools.nextRun'.tr}: ${item.nextRunDate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                if (item.lastRunDate?.trim().isNotEmpty == true)
                  Text(
                    '${'finance.tools.lastRun'.tr}: ${item.lastRunDate}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount and Currency Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                FinanceMoneyFormatter.signed(
                  item.amount,
                  item.currency,
                  debit: !isIncome,
                ),
                style: TextStyle(
                  color: isIncome
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.currency.apiValue,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          // Trailing More Button
          SizedBox(
            width: 32,
            child: isDeleting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    icon: const Icon(Icons.more_horiz_rounded),
                    onPressed: () => _showCardActions(
                      context: context,
                      title: item.title,
                      onDelete: onDelete,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. AUTO SAVE TAB (Matching Reference Screen 4)
// ============================================================================

class _AutoSaveTab extends StatelessWidget {
  const _AutoSaveTab({required this.controller});
  final FinanceToolsController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final items = controller.autoSaveRules.toList(growable: false);
    final active = items.where((item) => item.active).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: controller.loadAutoSaveRules,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Banner Card (Peach / Coral 3D Piggy Bank)
          _AutoSaveBannerCard(isDark: isDark),
          const SizedBox(height: AppSpacing.md),

          if (controller.isAutoSaveLoading.value && items.isEmpty)
            const _LoadingState()
          else if (controller.autoSaveErrorMessage.value != null &&
              items.isEmpty)
            _FinanceErrorState(
              message: controller.autoSaveErrorMessage.value!,
              onRetry: controller.loadAutoSaveRules,
            )
          else if (items.isEmpty) ...[
            _FinanceEmptyState(
              icon: Icons.savings_outlined,
              title: 'finance.tools.autoSaveEmpty'.tr,
              description: 'finance.tools.autoSaveEmptyNote'.tr,
              action: () => _showAutoSaveForm(context, controller),
            ),
            const SizedBox(height: 16),
            // Dashed Create Card in empty state
            _CreateRuleCard(
              title: 'finance.tools.createAutoSave'.tr,
              description: 'finance.tools.autoSaveEmptyNote'.tr,
              onTap: () => _showAutoSaveForm(context, controller),
            ),
          ] else ...[
            if (controller.autoSaveErrorMessage.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _FinanceErrorState(
                  message: controller.autoSaveErrorMessage.value!,
                  onRetry: controller.loadAutoSaveRules,
                  compact: true,
                ),
              ),

            // Active Rules Section
            _SectionHeader(
              title: 'finance.tools.activeRules'.tr,
              count: active.length,
              actionLabel: 'finance.seeAll'.tr,
            ),
            const SizedBox(height: AppSpacing.sm),

            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AutoSaveRuleCard(
                  item: item,
                  controller: controller,
                  onDelete: () => _confirmDelete(
                    context,
                    'finance.tools.deleteAutoSave'.tr,
                    () => controller.deleteAutoSaveRule(item.id),
                    () => controller.autoSaveMutationError.value,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Dashed Create Auto Save Rule Card
            _CreateRuleCard(
              title: 'finance.tools.createAutoSave'.tr,
              description: 'finance.tools.autoSaveEmptyNote'.tr,
              onTap: () => _showAutoSaveForm(context, controller),
            ),
          ],
        ],
      ),
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto Save Banner Card (Peach / Coral with Piggy Bank & Coins)
// ─────────────────────────────────────────────────────────────────────────────

class _AutoSaveBannerCard extends StatelessWidget {
  const _AutoSaveBannerCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF2E1020), const Color(0xFF1E1018)]
            : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? const Color(0xFF501E35)
            : const Color(0xFFFECDD3).withValues(alpha: 0.7),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.savings_rounded,
            color: Color(0xFFF43F5E),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'finance.tools.autoSave'.tr,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF881337),
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'finance.tools.autoSaveBannerNote'.tr,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFFDA4AF)
                      : const Color(0xFF9F1239),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto Save Rule Card (Matching Reference Screen 4)
// ─────────────────────────────────────────────────────────────────────────────

class _AutoSaveRuleCard extends StatelessWidget {
  const _AutoSaveRuleCard({
    required this.item,
    required this.controller,
    required this.onDelete,
  });

  final FinanceAutoSaveRuleEntity item;
  final FinanceToolsController controller;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDeleting = controller.deletingAutoSaveId.value == item.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Target Green Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Goal Title, Subtitle, and Currency Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.goalTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _autoSaveTypeLabel(item.type, item.percent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                if (item.lastRunDate?.trim().isNotEmpty == true)
                  Text(
                    '${'finance.tools.lastRun'.tr}: ${item.lastRunDate}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.currency.apiValue,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Trailing More Button
          SizedBox(
            width: 32,
            child: isDeleting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    icon: const Icon(Icons.more_horiz_rounded),
                    onPressed: () => _showCardActions(
                      context: context,
                      title: item.goalTitle,
                      onDelete: onDelete,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed Create Auto Save Rule Card (Matching Reference Screen 4)
// ─────────────────────────────────────────────────────────────────────────────

class _CreateRuleCard extends StatelessWidget {
  const _CreateRuleCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: isDark
              ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
              : const Color(0xFF93C5FD),
          strokeWidth: 1.5,
          radius: 18,
          dashWidth: 6,
          dashSpace: 4,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed Border Painter
// ─────────────────────────────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius;
}

// ============================================================================
// MODALS: CREATE RECURRING & AUTO SAVE (Matching Reference Screen 3)
// ============================================================================

Future<void> _showRecurringForm(
  BuildContext context,
  FinanceToolsController controller,
) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _RecurringFormBottomSheet(controller: controller),
  );

  if (created == true && context.mounted) {
    _showSuccess(context);
  }
}

class _RecurringFormBottomSheet extends StatefulWidget {
  const _RecurringFormBottomSheet({
    required this.controller,
  });

  final FinanceToolsController controller;

  @override
  State<_RecurringFormBottomSheet> createState() =>
      _RecurringFormBottomSheetState();
}

class _RecurringFormBottomSheetState extends State<_RecurringFormBottomSheet> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;

  var _type = FinanceRecurringType.expense;
  var _frequency = FinanceRecurringFrequency.monthly;
  var _currency = FinanceCurrency.usd;
  var _fromWallet = false;
  var _error = '';

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _amount = TextEditingController();
    _category = TextEditingController();
    _startDate = TextEditingController(text: _dateString(DateTime.now()));
    _endDate = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _category.dispose();
    _startDate.dispose();
    _endDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetHeight = math.max(
      0.0,
      math.min(760.0, media.size.height - media.viewInsets.bottom - 16),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 540, maxHeight: sheetHeight),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Grab Handle
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),

                // Header Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'finance.tools.createRecurring'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                // Form Fields List
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      if (_error.isNotEmpty) ...[
                        _FormErrorMessage(message: _error),
                        const SizedBox(height: 14),
                      ],

                      // 1. Type
                      _FieldLabel(label: 'finance.tools.type'.tr),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _RecurringTypeChoice(
                              label: _recurringTypeLabel(FinanceRecurringType.expense),
                              icon: Icons.arrow_downward_rounded,
                              accent: const Color(0xFFEF4444),
                              selected: _type == FinanceRecurringType.expense,
                              onTap: () => setState(() {
                                _type = FinanceRecurringType.expense;
                                _error = '';
                              }),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RecurringTypeChoice(
                              label: _recurringTypeLabel(FinanceRecurringType.income),
                              icon: Icons.arrow_upward_rounded,
                              accent: const Color(0xFF10B981),
                              selected: _type == FinanceRecurringType.income,
                              onTap: () => setState(() {
                                _type = FinanceRecurringType.income;
                                _error = '';
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Title
                      _FieldLabel(label: 'finance.tools.titleField'.tr),
                      const SizedBox(height: 6),
                      _ModernTextInput(
                        controller: _title,
                        hint: 'e.g. Netflix subscription',
                        maxLength: 160,
                        onChanged: (_) => setState(() => _error = ''),
                      ),
                      const SizedBox(height: 14),

                      // 3. Amount
                      _FieldLabel(label: 'finance.tools.amount'.tr),
                      const SizedBox(height: 6),
                      _ModernTextInput(
                        controller: _amount,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() => _error = ''),
                      ),
                      const SizedBox(height: 14),

                      // 4. Currency
                      _FieldLabel(label: 'finance.tools.currency'.tr),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<FinanceCurrency>(
                        initialValue: _currency,
                        decoration: _modernInputDecoration(context),
                        items: FinanceCurrency.values
                            .map((v) => DropdownMenuItem(value: v, child: Text(v.apiValue)))
                            .toList(),
                        onChanged: (value) => setState(() {
                          if (value != null) _currency = value;
                          _error = '';
                        }),
                      ),
                      const SizedBox(height: 14),

                      // 5. Category (optional)
                      _FieldLabel(label: 'finance.tools.category'.tr),
                      const SizedBox(height: 6),
                      _ModernTextInput(
                        controller: _category,
                        hint: 'Select category',
                        prefixIcon: Icons.category_outlined,
                        maxLength: 80,
                        onChanged: (_) => setState(() => _error = ''),
                      ),
                      const SizedBox(height: 14),

                      // 6. Frequency
                      _FieldLabel(label: 'finance.tools.frequency'.tr),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<FinanceRecurringFrequency>(
                        initialValue: _frequency,
                        decoration: _modernInputDecoration(
                          context,
                          prefixIcon: Icons.calendar_month_outlined,
                        ),
                        items: FinanceRecurringFrequency.values
                            .map((v) => DropdownMenuItem(value: v, child: Text(_frequencyLabel(v))))
                            .toList(),
                        onChanged: (value) => setState(() {
                          if (value != null) _frequency = value;
                        }),
                      ),
                      const SizedBox(height: 14),

                      // 7. Start date
                      _FieldLabel(label: 'finance.tools.startDate'.tr),
                      const SizedBox(height: 6),
                      _ModernDateField(
                        controller: _startDate,
                        prefixIcon: Icons.calendar_today_outlined,
                        onChanged: (_) => setState(() => _error = ''),
                      ),
                      const SizedBox(height: 14),

                      // 8. End date (optional)
                      _FieldLabel(label: 'finance.tools.endDateOptional'.tr),
                      const SizedBox(height: 6),
                      _ModernDateField(
                        controller: _endDate,
                        optional: true,
                        hint: 'Select date',
                        prefixIcon: Icons.calendar_today_outlined,
                        onChanged: (_) => setState(() => _error = ''),
                      ),
                      const SizedBox(height: 14),

                      // 9. Pay from wallet
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'finance.tools.fromWallet'.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Use balance from your wallet when available.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _fromWallet,
                              activeThumbColor: AppColors.brandPrimary,
                              onChanged: (val) => setState(() => _fromWallet = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Action Buttons (Cancel / Create)
                _ModalBottomActions(
                  onCancel: () => Navigator.pop(context, false),
                  onCreate: () async {
                    final localError = _recurringFormError(
                      title: _title.text,
                      amount: _amount.text,
                      startDate: _startDate.text,
                      endDate: _endDate.text,
                      category: _category.text,
                    );
                    if (localError != null) {
                      setState(() => _error = localError);
                      return;
                    }
                    final ok = await widget.controller.createRecurringTransaction(
                      type: _type,
                      title: _title.text,
                      amountText: _amount.text,
                      frequency: _frequency,
                      startDate: _startDate.text,
                      currency: _currency,
                      category: _category.text,
                      fromWallet: _fromWallet,
                      endDate: _endDate.text.trim().isEmpty ? null : _endDate.text.trim(),
                    );
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.of(context).pop(true);
                    } else {
                      setState(() {
                        _error = widget.controller.recurringMutationError.value ?? 'common.error'.tr;
                      });
                    }
                  },
                  isSubmitting: widget.controller.isRecurringSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showAutoSaveForm(
  BuildContext context,
  FinanceToolsController controller,
) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AutoSaveFormBottomSheet(controller: controller),
  );

  if (created == true && context.mounted) {
    _showSuccess(context);
  }
}

class _AutoSaveFormBottomSheet extends StatefulWidget {
  const _AutoSaveFormBottomSheet({
    required this.controller,
  });

  final FinanceToolsController controller;

  @override
  State<_AutoSaveFormBottomSheet> createState() =>
      _AutoSaveFormBottomSheetState();
}

class _AutoSaveFormBottomSheetState extends State<_AutoSaveFormBottomSheet> {
  late final TextEditingController _percent;
  var _currency = FinanceCurrency.usd;
  var _type = FinanceAutoSaveType.percentOfIncome;
  var _goalId = '';
  var _error = '';

  @override
  void initState() {
    super.initState();
    _percent = TextEditingController();
    unawaited(widget.controller.loadSavingGoals(_currency));
  }

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetHeight = math.max(
      0.0,
      math.min(700.0, media.size.height - media.viewInsets.bottom - 16),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 540, maxHeight: sheetHeight),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Obx(
              () => Column(
                children: [
                  // Grab Handle
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'finance.tools.createAutoSave'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      children: [
                        if (_error.isNotEmpty) ...[
                          _FormErrorMessage(message: _error),
                          const SizedBox(height: 14),
                        ],

                        // Currency
                        _FieldLabel(label: 'finance.tools.currency'.tr),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<FinanceCurrency>(
                          initialValue: _currency,
                          decoration: _modernInputDecoration(context),
                          items: FinanceCurrency.values
                              .map((v) => DropdownMenuItem(value: v, child: Text(v.apiValue)))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _currency = value;
                              _goalId = '';
                              _error = '';
                            });
                            unawaited(widget.controller.loadSavingGoals(value));
                          },
                        ),
                        const SizedBox(height: 14),

                        // Savings Goal
                        _FieldLabel(label: 'finance.tools.goal'.tr),
                        const SizedBox(height: 6),
                        if (widget.controller.isGoalsLoading.value)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        else if (widget.controller.goalsErrorMessage.value != null)
                          _RetryMessage(
                            message: widget.controller.goalsErrorMessage.value!,
                            onRetry: () => unawaited(widget.controller.loadSavingGoals(_currency)),
                          )
                        else if (widget.controller.savingGoals.isEmpty)
                          _EmptyMessage(title: 'finance.tools.noGoals'.tr)
                        else
                          DropdownButtonFormField<String>(
                            initialValue: widget.controller.savingGoals.any((g) => g.savingGoalId == _goalId)
                                ? _goalId
                                : null,
                            decoration: _modernInputDecoration(context),
                            items: widget.controller.savingGoals
                                .map((g) => DropdownMenuItem(value: g.savingGoalId, child: Text(g.title)))
                                .toList(),
                            onChanged: (value) => setState(() {
                              _goalId = value ?? '';
                              _error = '';
                            }),
                          ),
                        const SizedBox(height: 14),

                        // Auto Save Method
                        _FieldLabel(label: 'finance.tools.autoSaveType'.tr),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<FinanceAutoSaveType>(
                          initialValue: _type,
                          decoration: _modernInputDecoration(context),
                          items: FinanceAutoSaveType.values
                              .map((v) => DropdownMenuItem(value: v, child: Text(_autoSaveTypeLabel(v))))
                              .toList(),
                          onChanged: (value) => setState(() {
                            if (value != null) _type = value;
                          }),
                        ),
                        const SizedBox(height: 14),

                        // Percent of income (if applicable)
                        if (_type == FinanceAutoSaveType.percentOfIncome) ...[
                          _FieldLabel(label: 'finance.tools.percent'.tr),
                          const SizedBox(height: 6),
                          _ModernTextInput(
                            controller: _percent,
                            hint: '10.0',
                            suffixText: '%',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() => _error = ''),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),

                  // Bottom Action Buttons
                  _ModalBottomActions(
                    onCancel: () => Navigator.pop(context, false),
                    onCreate: () async {
                      final localError = _autoSaveFormError(
                        goalId: _goalId,
                        goals: widget.controller.savingGoals,
                        type: _type,
                        percentText: _percent.text,
                      );
                      if (localError != null) {
                        setState(() => _error = localError);
                        return;
                      }
                      final ok = await widget.controller.createAutoSaveRule(
                        savingGoalId: _goalId,
                        type: _type,
                        percentText: _percent.text,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop(true);
                      } else {
                        setState(() {
                          _error = widget.controller.autoSaveMutationError.value ?? 'common.error'.tr;
                        });
                      }
                    },
                    isSubmitting: widget.controller.isAutoSaveSubmitting,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MODAL REUSABLE FORM COMPONENTS
// ============================================================================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

InputDecoration _modernInputDecoration(
  BuildContext context, {
  IconData? prefixIcon,
  String? hint,
  String? suffixText,
}) {
  final colors = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    ),
  );

  return InputDecoration(
    hintText: hint,
    suffixText: suffixText,
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, size: 20, color: colors.onSurfaceVariant)
        : null,
    filled: true,
    fillColor: isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
        : const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
    ),
  );
}

class _ModernTextInput extends StatelessWidget {
  const _ModernTextInput({
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixText,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLength: maxLength,
    onChanged: onChanged,
    decoration: _modernInputDecoration(
      context,
      hint: hint,
      prefixIcon: prefixIcon,
      suffixText: suffixText,
    ),
  );
}

class _ModernDateField extends StatelessWidget {
  const _ModernDateField({
    required this.controller,
    this.optional = false,
    this.hint,
    this.prefixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool optional;
  final String? hint;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly: true,
    decoration: _modernInputDecoration(
      context,
      hint: hint,
      prefixIcon: prefixIcon,
    ).copyWith(
      suffixIcon: optional && controller.text.isNotEmpty
          ? IconButton(
              onPressed: () {
                controller.clear();
                onChanged?.call('');
              },
              icon: const Icon(Icons.close_rounded, size: 18),
            )
          : const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
    ),
    onTap: () async {
      final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        controller.text = _dateString(date);
        onChanged?.call(controller.text);
      }
    },
  );
}

class _RecurringTypeChoice extends StatelessWidget {
  const _RecurringTypeChoice({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected
          ? accent.withValues(alpha: isDark ? 0.18 : 0.08)
          : (isDark ? const Color(0xFF0F172A) : Colors.white),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF334155) : colors.outlineVariant),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? accent : colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? accent : colors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalBottomActions extends StatelessWidget {
  const _ModalBottomActions({
    required this.onCancel,
    required this.onCreate,
    required this.isSubmitting,
  });

  final VoidCallback onCancel;
  final VoidCallback onCreate;
  final RxBool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel Button
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                side: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text(
                'common.cancel'.tr,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Create Button (FilledButton per test expectation)
          Expanded(
            child: Obx(
              () => FilledButton(
                onPressed: isSubmitting.value ? null : onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: isSubmitting.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'finance.tools.create'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CARD ACTION SHEET (Delete confirmation integration)
// ============================================================================

void _showCardActions({
  required BuildContext context,
  required String title,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: Text(
                'common.delete'.tr,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
          ],
        ),
      );
    },
  );
}

// ============================================================================
// CONFIRMATION DIALOG (Using existing GenLinkConfirmDialog)
// ============================================================================

Future<void> _confirmDelete(
  BuildContext context,
  String title,
  Future<bool> Function() remove,
  String? Function() errorMessage,
) async {
  final confirmed = await GenLinkConfirmDialog.showDanger(
    context: context,
    title: title,
    message: 'finance.tools.deleteConfirm'.tr,
    confirmLabel: 'common.delete'.tr,
    cancelLabel: 'common.cancel'.tr,
  );
  if (confirmed != true) return;
  final ok = await remove();
  if (context.mounted) {
    if (ok) {
      _showSuccess(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage() ?? 'finance.tools.actionFailed'.tr)),
      );
    }
  }
}

// ============================================================================
// SECTION HEADERS, EMPTY & ERROR STATES
// ============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.count,
    this.actionLabel,
    this.actionWidget,
    this.onAction,
  });

  final String title;
  final int? count;
  final String? actionLabel;
  final Widget? actionWidget;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayTitle = count != null && !title.contains('(')
        ? '$title ($count)'
        : title;

    Widget? action;
    if (actionWidget != null) {
      action = actionWidget;
    } else if (actionLabel != null) {
      final labelWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ),
      );

      action = onAction != null
          ? InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onAction,
              child: labelWidget,
            )
          : labelWidget;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            displayTitle,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class _FinanceEmptyState extends StatelessWidget {
  const _FinanceEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('finance.tools.create'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                  side: const BorderSide(color: AppColors.brandPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyMessage extends StatelessWidget {
  const _InlineEmptyMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _FinanceErrorState extends StatelessWidget {
  const _FinanceErrorState({
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.errorContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: colors.onErrorContainer, fontSize: 12))),
            TextButton(
              onPressed: onRetry,
              child: Text('common.retry'.tr, style: TextStyle(color: colors.error)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: colors.error),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: colors.onSurface, fontSize: 14)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text('common.retry'.tr),
          ),
        ],
      ),
    );
  }
}

class _FormErrorMessage extends StatelessWidget {
  const _FormErrorMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
      TextButton(onPressed: onRetry, child: Text('common.retry'.tr)),
    ],
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(title, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
  );
}

// ============================================================================
// VALIDATION & HELPER UTILITIES
// ============================================================================

String? _recurringFormError({
  required String title,
  required String amount,
  required String startDate,
  required String endDate,
  required String category,
}) {
  if (title.trim().isEmpty || title.trim().length > 160) {
    return 'finance.tools.validationTitle'.tr;
  }
  final exactAmount = FinanceMoney.tryParseInput(amount);
  if (exactAmount == null || exactAmount.sign <= 0) {
    return 'finance.tools.validationAmount'.tr;
  }
  final start = _parseExactDate(startDate);
  if (start == null) return 'finance.tools.validationStartDate'.tr;
  if (endDate.trim().isNotEmpty) {
    final end = _parseExactDate(endDate.trim());
    if (end == null || end.isBefore(start)) {
      return 'finance.tools.validationDateRange'.tr;
    }
  }
  if (category.trim().length > 80) {
    return 'finance.tools.validationCategory'.tr;
  }
  return null;
}

String? _autoSaveFormError({
  required String goalId,
  required Iterable<FinanceSavingGoalEntity> goals,
  required FinanceAutoSaveType type,
  required String percentText,
}) {
  if (!goals.any((goal) => goal.savingGoalId == goalId)) {
    return 'finance.tools.selectGoal'.tr;
  }
  if (type == FinanceAutoSaveType.percentOfIncome) {
    final value = FinanceMoney.tryParseInput(percentText);
    if (value == null ||
        value.sign <= 0 ||
        value.compareTo(FinanceMoney.tryParseInput('100')!) > 0) {
      return 'finance.tools.validationPercent'.tr;
    }
  }
  return null;
}

DateTime? _parseExactDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return _dateString(parsed) == value ? parsed : null;
}

String _monthLabel(int month, int year) {
  final months = 'date.months'.tr.split(',');
  return month > 0 && month <= months.length
      ? '${months[month - 1]} $year'
      : '$month/$year';
}

String _dateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _recurringTypeLabel(FinanceRecurringType type) =>
    type == FinanceRecurringType.income
        ? 'finance.tools.incomeType'.tr
        : 'finance.tools.expenseType'.tr;

String _frequencyLabel(FinanceRecurringFrequency value) => switch (value) {
  FinanceRecurringFrequency.daily => 'finance.tools.daily'.tr,
  FinanceRecurringFrequency.weekly => 'finance.tools.weekly'.tr,
  FinanceRecurringFrequency.monthly => 'finance.tools.monthly'.tr,
};

String _autoSaveTypeLabel(FinanceAutoSaveType value, [double? percent]) =>
    switch (value) {
      FinanceAutoSaveType.percentOfIncome =>
        'finance.tools.percentOfIncome'.trParams({
          'percent': percent?.toStringAsFixed(2) ?? '',
        }),
      FinanceAutoSaveType.roundUp => 'finance.tools.roundUp'.tr,
    };

IconData _insightIcon(String severity) => switch (severity.toUpperCase()) {
  'HIGH' => Icons.warning_amber_rounded,
  'MEDIUM' => Icons.track_changes_rounded,
  _ => Icons.bar_chart_rounded,
};

Color _insightColor(BuildContext context, String severity) =>
    severity.toUpperCase() == 'HIGH'
        ? const Color(0xFFEF4444)
        : severity.toUpperCase() == 'MEDIUM'
            ? const Color(0xFFF97316)
            : const Color(0xFF10B981);

void _showSuccess(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('finance.tools.saved'.tr)),
);

FinanceCashFlowEntity? _previousPeriodCashFlow(
  FinanceController finance,
  FinanceCurrency currency,
  int month,
  int year,
) {
  final prev = DateTime(year, month - 1, 1);
  final flow = finance.previousPeriodCashFlow.value;
  if (flow?.currency == currency && flow?.month == prev.month && flow?.year == prev.year) {
    return flow;
  }
  return null;
}
