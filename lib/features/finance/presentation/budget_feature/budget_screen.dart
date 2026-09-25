import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/budget_feature/budget_set_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/budget_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

/// Modern fintech monthly budget view.
///
/// Fully aligned with the project Design System, supporting large financial
/// values, extreme percentages, Khmer locale, and adaptive light/dark theming.
class BudgetScreen extends GetView<BudgetController> {
  const BudgetScreen({super.key});

  FinanceController? get financeController =>
      Get.isRegistered<FinanceController>() ? Get.find<FinanceController>() : null;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = semantic.background;
    final surface = semantic.surface;
    final surfaceSecondary = semantic.backgroundSecondary;
    final textPrimary = semantic.primaryText;
    final textSecondary = semantic.secondaryText;
    final textMuted = semantic.textMuted;
    final border = semantic.borderSubtle;
    final primary = semantic.primary;

    return Obx(() {
      final value = controller.budget.value;
      final loading = controller.isLoading.value;
      final error = controller.listErrorMessage.value;
      final currency = controller.selectedCurrency.value;

      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
              children: [
                // ── 1. Header (Back, Title & Subtitle, Add Budget) ───────────
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'finance.budget.title'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'finance.budget.subtitle'.tr,
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
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SetBudgetScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(22),
                        child: Ink(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 24,
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 2. Currency Segmented Bar ────────────────────────────────
                _CurrencyBar(
                  currency: currency,
                  onChanged: controller.selectCurrency,
                  surface: surface,
                  border: border,
                  primary: primary,
                  text: textPrimary,
                  textMuted: textMuted,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // ── 3. Period / Month Selector ───────────────────────────────
                _PeriodBar(
                  month: controller.selectedMonth.value,
                  year: controller.selectedYear.value,
                  onPrevious: controller.selectPreviousMonth,
                  onNext: controller.selectNextMonth,
                  background: surface,
                  borderColor: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 16),

                // ── 4. Main Content / States ──────────────────────────────────
                if (loading && value == null)
                  const SizedBox(height: 360, child: AppLoader())
                else if (error != null && value == null)
                  SizedBox(
                    height: 360,
                    child: AppEmptyState(
                      message: error,
                      icon: Icons.cloud_off_outlined,
                      action: AppButton.secondary(
                        label: 'common.retry'.tr,
                        onPressed: controller.load,
                        height: 46,
                      ),
                    ),
                  )
                else if (value == null)
                  SizedBox(
                    height: 360,
                    child: AppEmptyState(
                      message: 'finance.budget.noBudget'.tr,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  )
                else
                  _BudgetContent(
                    budget: value,
                    surface: surface,
                    secondary: surfaceSecondary,
                    text: textPrimary,
                    textSecondary: textSecondary,
                    muted: textMuted,
                    border: border,
                    primary: primary,
                    isDark: isDark,
                    financialTip: financeController?.dashboard.value?.financialTip,
                    onOpenDetail: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BudgetDetailScreen(budget: value),
                      ),
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

class _CurrencyBar extends StatelessWidget {
  const _CurrencyBar({
    required this.currency,
    required this.onChanged,
    required this.surface,
    required this.border,
    required this.primary,
    required this.text,
    required this.textMuted,
    required this.isDark,
  });

  final FinanceCurrency currency;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color surface;
  final Color border;
  final Color primary;
  final Color text;
  final Color textMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isUsd = currency == FinanceCurrency.usd;
    final activeIndicatorColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFF0F172A);

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
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: isUsd ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.25)
                      : activeIndicatorColor,
                  borderRadius: BorderRadius.circular(10),
                  border: isDark
                      ? Border.all(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                          width: 1,
                        )
                      : null,
                ),
              ),
            ),
          ),
          Row(
            children: FinanceCurrency.values.map((value) {
              final selected = value == currency;
              final activeTextColor =
                  isDark ? const Color(0xFF2DD4BF) : Colors.white;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(value),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        color: selected ? activeTextColor : textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
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

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.month,
    required this.year,
    required this.onPrevious,
    required this.onNext,
    required this.background,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
  });

  final int month;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Color background;
  final Color borderColor;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    const englishFullMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final isKhmer = Get.locale?.languageCode == 'km';
    final names = 'date.months'.tr.split(',');
    final monthName = !isKhmer && month >= 1 && month <= 12
        ? englishFullMonths[month - 1]
        : (month >= 1 && month <= names.length ? names[month - 1] : '$month');
    final label = '$monthName $year';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            splashRadius: 20,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: textPrimary,
              size: 22,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: textPrimary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            splashRadius: 20,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: textPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetContent extends StatelessWidget {
  const _BudgetContent({
    required this.budget,
    required this.surface,
    required this.secondary,
    required this.text,
    required this.textSecondary,
    required this.muted,
    required this.border,
    required this.primary,
    required this.isDark,
    required this.onOpenDetail,
    this.financialTip,
  });

  final FinanceBudgetEntity budget;
  final Color surface;
  final Color secondary;
  final Color text;
  final Color textSecondary;
  final Color muted;
  final Color border;
  final Color primary;
  final bool isDark;
  final VoidCallback onOpenDetail;
  final String? financialTip;

  @override
  Widget build(BuildContext context) {
    final progress = budget.totalBudget <= 0
        ? 0.0
        : (budget.spentAmount / budget.totalBudget).clamp(0.0, 1.0);
    final percent = budget.totalBudget <= 0
        ? 0
        : ((budget.spentAmount / budget.totalBudget) * 100).round();
    final statusColor = _statusColor(budget.status);
    final isLimitReached = budget.status.toUpperCase() == 'LIMIT_REACHED' ||
        budget.spentAmount > budget.totalBudget;
    final accentActionColor =
        isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    final overAmount = (budget.spentAmount - budget.totalBudget).abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main Budget Card ─────────────────────────────────────────────────
        _SurfaceCard(
          color: surface,
          borderColor: border,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header inside card: Total Budget label & Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'finance.budget.totalBudget'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: budget.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 6),

              // Large Budget Amount
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  FinanceMoneyFormatter.format(
                    budget.totalBudget,
                    budget.currency,
                  ),
                  maxLines: 1,
                  style: TextStyle(
                    color: text,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: secondary,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 10),

              // Percentage used and Remaining balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$percent% ${'finance.budget.used'.tr.toLowerCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isLimitReached ? AppColors.danger : muted,
                        fontSize: 12,
                        fontWeight: isLimitReached
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${FinanceMoneyFormatter.format(budget.remainingAmount, budget.currency)} ${'finance.budget.remaining'.tr.toLowerCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: budget.remainingAmount < 0
                            ? AppColors.danger
                            : statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // Limit-Reached Warning Banner
              if (isLimitReached) ...[
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpenDetail,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.danger.withValues(alpha: 0.15)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.danger.withValues(alpha: 0.35)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.priority_high_rounded,
                              color: AppColors.danger,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'finance.budget.exceededTitle'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF991B1B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'finance.budget.exceededDescription'.trParams({
                                    'amount': FinanceMoneyFormatter.format(
                                      overAmount,
                                      budget.currency,
                                    ),
                                  }),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFFCA5A5)
                                        : const Color(0xFFB91C1C),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFFB91C1C),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── 2. Budget Overview ───────────────────────────────────────────────
        Text(
          'finance.budget.overview'.tr,
          style: TextStyle(
            color: text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'finance.budget.totalBudget'.tr,
                value: FinanceMoneyFormatter.format(
                  budget.totalBudget,
                  budget.currency,
                ),
                surface: surface,
                border: border,
                textPrimary: text,
                textMuted: muted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFFF43F5E),
                title: 'finance.budget.spent'.tr,
                value: FinanceMoneyFormatter.format(
                  budget.spentAmount,
                  budget.currency,
                ),
                surface: surface,
                border: border,
                textPrimary: text,
                textMuted: muted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                icon: Icons.savings_rounded,
                iconColor: budget.remainingAmount < 0
                    ? AppColors.danger
                    : AppColors.financeAccent,
                title: 'finance.budget.remaining'.tr,
                value: FinanceMoneyFormatter.format(
                  budget.remainingAmount,
                  budget.currency,
                ),
                valueColor: budget.remainingAmount < 0
                    ? AppColors.danger
                    : AppColors.financeAccent,
                surface: surface,
                border: border,
                textPrimary: text,
                textMuted: muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── 3. Category Budgets ──────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'finance.budget.categoryBudgets'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            GestureDetector(
              onTap: onOpenDetail,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: Text(
                  'finance.budget.manage'.tr,
                  style: TextStyle(
                    color: accentActionColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (budget.categories.isEmpty)
          _SurfaceCard(
            color: surface,
            borderColor: border,
            padding: const EdgeInsets.all(18),
            child: Center(
              child: Text(
                'finance.budget.noCategories'.tr,
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ),
          )
        else
          ...budget.categories.map((category) {
            final catColor = _categoryColor(category.category);
            final catIcon = _categoryIcon(category.category);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SurfaceCard(
                color: surface,
                borderColor: border,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: _CategoryBudgetRow(
                  category: category,
                  currency: budget.currency,
                  icon: catIcon,
                  color: catColor,
                  textPrimary: text,
                  textSecondary: textSecondary,
                  textMuted: muted,
                  secondaryBg: secondary,
                  onTap: onOpenDetail,
                ),
              ),
            );
          }),
        const SizedBox(height: 12),

        // ── 4. Smart Tip ─────────────────────────────────────────────────────
        _SmartTipCard(
          surface: surface,
          border: border,
          textPrimary: text,
          textMuted: muted,
          tipText: financialTip ?? 'finance.budget.defaultSmartTip'.tr,
          onTap: onOpenDetail,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.valueColor,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color? valueColor;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      color: surface,
      borderColor: border,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: valueColor ?? textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetRow extends StatelessWidget {
  const _CategoryBudgetRow({
    required this.category,
    required this.currency,
    required this.icon,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.secondaryBg,
    required this.onTap,
  });

  final FinanceCategoryBudget category;
  final FinanceCurrency currency;
  final IconData icon;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color secondaryBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = category.allocatedAmount <= 0
        ? 0.0
        : (category.spentAmount / category.allocatedAmount).clamp(0.0, 1.0);
    final percent = category.allocatedAmount <= 0
        ? 0
        : ((category.spentAmount / category.allocatedAmount) * 100).round();
    final isOver = percent > 100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category squircle icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Name, amounts and progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _localizedCategoryName(category.category),
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
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${FinanceMoneyFormatter.format(category.spentAmount, currency)} / ${FinanceMoneyFormatter.format(category.allocatedAmount, currency)}',
                              maxLines: 1,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            maxWidth: 54,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$percent%',
                              maxLines: 1,
                              style: TextStyle(
                                color: isOver ? AppColors.danger : textMuted,
                                fontSize: 12,
                                fontWeight: isOver
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: textMuted.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: secondaryBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOver ? AppColors.danger : color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartTipCard extends StatelessWidget {
  const _SmartTipCard({
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.tipText,
    required this.onTap,
  });

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final String tipText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: _SurfaceCard(
          color: surface,
          borderColor: border,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.warning,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'finance.budget.smartTip'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tipText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: textMuted.withValues(alpha: 0.6),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    required this.color,
    required this.borderColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _statusLabel(String raw) {
    switch (raw.toUpperCase()) {
      case 'LIMIT_REACHED':
        return 'finance.budget.limitReached'.tr;
      case 'WARNING':
        return 'finance.budget.nearLimit'.tr;
      case 'SAFE':
        return 'finance.budget.onTrack'.tr;
      default:
        return raw;
    }
  }
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'LIMIT_REACHED':
      return AppColors.danger;
    case 'WARNING':
      return AppColors.warning;
    case 'SAFE':
      return AppColors.success;
    default:
      return AppColors.brandPrimary;
  }
}

IconData _categoryIcon(String? category) {
  switch (category?.toUpperCase()) {
    case 'FOOD':
    case 'FOOD & DRINKS':
      return Icons.restaurant_rounded;
    case 'TRAVEL':
      return Icons.flight_rounded;
    case 'TRANSPORT':
      return Icons.directions_car_rounded;
    case 'STUDY':
      return Icons.menu_book_rounded;
    case 'BILLS':
    case 'UTILITIES':
      return Icons.home_rounded;
    case 'SHOPPING':
      return Icons.shopping_bag_rounded;
    case 'ENTERTAINMENT':
    case 'HEALTH':
      return Icons.favorite_rounded;
    default:
      return Icons.more_horiz_rounded;
  }
}

Color _categoryColor(String? category) {
  switch (category?.toUpperCase()) {
    case 'BILLS':
    case 'UTILITIES':
      return AppColors.productivityAccent;
    case 'FOOD':
    case 'FOOD & DRINKS':
      return AppColors.warning;
    case 'TRAVEL':
      return const Color(0xFF38BDF8);
    case 'TRANSPORT':
      return const Color(0xFFF43F5E);
    case 'SHOPPING':
      return AppColors.financeAccent;
    case 'STUDY':
      return AppColors.brandPrimary;
    default:
      return AppColors.growthAccent;
  }
}

String _localizedCategoryName(String category) {
  switch (category.toUpperCase()) {
    case 'FOOD':
    case 'FOOD & DRINKS':
      return 'finance.food'.tr;
    case 'TRANSPORT':
      return 'finance.transport'.tr;
    case 'BILLS':
    case 'UTILITIES':
      return 'finance.bills'.tr;
    case 'SHOPPING':
      return 'finance.shopping'.tr;
    case 'ENTERTAINMENT':
      return 'finance.entertainment'.tr;
    case 'STUDY':
      return 'finance.expense.study'.tr;
    case 'HEALTH':
      return 'finance.expense.health'.tr;
    case 'OTHER':
    case 'OTHERS':
      return 'finance.other'.tr;
    default:
      return category;
  }
}
