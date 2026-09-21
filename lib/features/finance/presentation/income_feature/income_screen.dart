import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/finance_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/income_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_detail_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/cash_flow_feature/cash_flow_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _sourceController = TextEditingController();
  final _scrollController = ScrollController();
  var _showSearchField = false;

  IncomeController get controller => Get.find<IncomeController>();
  FinanceController get financeController => Get.find<FinanceController>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      controller.loadNextPage();
    }
  }

  Future<void> _applySource() async {
    FocusScope.of(context).unfocus();
    await controller.selectSource(_sourceController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;
    final text = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final inverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final incomes = controller.incomes.toList(growable: false);
          final loading = controller.isInitialLoading.value;
          final error = controller.listErrorMessage.value;
          final currency = controller.selectedCurrency.value;
          final selectedSource = controller.selectedSource.value;

          final totalIncome = incomes.fold<double>(
            0.0,
            (sum, item) => sum + item.amount,
          );

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait<void>([
                controller.refresh(),
                financeController.reload(),
              ]);
            },
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // ── 1. Top Header ───────────────────────────────────────────
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
                            'finance.income.title'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: text,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'finance.income.subtitle'.tr,
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
                    IconButton(
                      tooltip: 'finance.cashFlow.title'.tr,
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CashFlowScreen(),
                        ),
                      ),
                      icon: Icon(Icons.compare_arrows_rounded, color: text),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IncomeAddScreen(),
                          ),
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.add_rounded,
                            color: inverse,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 2. Currency Segmented Toggle ─────────────────────────────
                _CurrencyBar(
                  value: currency,
                  onChanged: controller.selectCurrency,
                  text: text,
                  muted: muted,
                  surface: surface,
                  border: border,
                  primary: primary,
                ),
                const SizedBox(height: 12),

                // ── 3. Period / Month Selector ───────────────────────────────
                _PeriodBar(
                  surface: surface,
                  border: border,
                  text: text,
                  muted: muted,
                  dashboardMonth: financeController.dashboard.value?.month,
                ),
                const SizedBox(height: 16),

                // ── 4. Main Content / States ──────────────────────────────────
                if (loading && incomes.isEmpty)
                  const SizedBox(height: 280, child: AppLoader())
                else if (error != null && incomes.isEmpty)
                  SizedBox(
                    height: 280,
                    child: AppEmptyState(
                      message: error,
                      icon: Icons.cloud_off_outlined,
                      action: AppButton.secondary(
                        label: 'common.retry'.tr,
                        expanded: false,
                        onPressed: controller.loadInitial,
                      ),
                    ),
                  )
                else if (incomes.isEmpty && selectedSource == null)
                  SizedBox(
                    height: 280,
                    child: AppEmptyState(
                      message: 'finance.income.empty'.tr,
                      icon: Icons.trending_up_rounded,
                    ),
                  )
                else ...[
                  // ── Hero Total Income Card ─────────────────────────────────
                  _TotalIncomeHeroCard(
                    totalIncome: totalIncome,
                    currency: currency,
                    surface: surface,
                    border: border,
                    text: text,
                    muted: muted,
                  ),
                  const SizedBox(height: 22),

                  // ── Income by Source Section ───────────────────────────────
                  _IncomeBySourceSection(
                    incomes: incomes,
                    totalIncome: totalIncome,
                    currency: currency,
                    selectedSource: selectedSource,
                    onSelectSource: (source) {
                      if (selectedSource == source) {
                        controller.selectSource(null);
                      } else {
                        controller.selectSource(source);
                      }
                    },
                    onToggleSearch: () {
                      setState(() {
                        _showSearchField = !_showSearchField;
                      });
                    },
                    searchController: _sourceController,
                    showSearch: _showSearchField,
                    onClearFilter: () {
                      _sourceController.clear();
                      controller.selectSource(null);
                    },
                    onApplySearch: _applySource,
                    surface: surface,
                    surfaceSecondary: surfaceSecondary,
                    border: border,
                    text: text,
                    muted: muted,
                    primary: primary,
                  ),
                  const SizedBox(height: 22),

                  // ── Recent Income Section ──────────────────────────────────
                  _RecentIncomeSection(
                    incomes: incomes,
                    currency: currency,
                    surface: surface,
                    border: border,
                    text: text,
                    muted: muted,
                    onTapIncome: _openDetail,
                  ),

                  // ── Pagination Loader / Error ──────────────────────────────
                  if (controller.isLoadingMore.value)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: AppLoader(size: 22),
                    ),

                  if (controller.paginationErrorMessage.value != null)
                    _PaginationError(
                      message: controller.paginationErrorMessage.value!,
                      onRetry: controller.loadNextPage,
                      textMuted: muted,
                    ),

                  const SizedBox(height: 20),

                  // ── Smart Insight Card ─────────────────────────────────────
                  _SmartInsightCard(
                    surface: surface,
                    border: border,
                    text: text,
                    muted: muted,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        }),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.of(context).padding.bottom + 10,
        ),
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border)),
        ),
        child: AppButton(
          label: 'finance.income.add'.tr,
          icon: Icons.add_rounded,
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const IncomeAddScreen(),
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(FinanceIncomeEntity income) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => IncomeDetailScreen.fromEntity(
          income,
          onEdit: () {
            Navigator.pop(context);
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => IncomeAddScreen(income: income),
              ),
            );
          },
          onDeleted: () => controller.deleteIncome(income.incomeId),
        ),
      ),
    );
  }
}

class _CurrencyBar extends StatelessWidget {
  const _CurrencyBar({
    required this.value,
    required this.onChanged,
    required this.text,
    required this.muted,
    required this.surface,
    required this.border,
    required this.primary,
  });

  final FinanceCurrency value;
  final ValueChanged<FinanceCurrency> onChanged;
  final Color text;
  final Color muted;
  final Color surface;
  final Color border;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final currencies = FinanceCurrency.values;
    final isUsd = value == FinanceCurrency.usd;

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
            children: currencies.map((currency) {
              final selected = currency == value;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(currency),
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
                      child: Text(currency.apiValue),
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
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    this.dashboardMonth,
  });

  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final FinanceMonthOverview? dashboardMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = dashboardMonth?.month ?? now.month;
    final year = dashboardMonth?.year ?? now.year;

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthName = months[(month - 1).clamp(0, 11)];
    final periodLabel = '$monthName $year';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.chevron_left_rounded,
            color: muted,
            size: 22,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: text,
              ),
              const SizedBox(width: 8),
              Text(
                periodLabel,
                style: TextStyle(
                  color: text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: muted,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _TotalIncomeHeroCard extends StatelessWidget {
  const _TotalIncomeHeroCard({
    required this.totalIncome,
    required this.currency,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
  });

  final double totalIncome;
  final FinanceCurrency currency;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final compactValue = _compactMoney(totalIncome, currency);
    final previousAmount = totalIncome * 0.86;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: amounts and comparison
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'finance.income.totalIncome'.tr,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    FinanceMoneyFormatter.format(totalIncome, currency),
                    style: TextStyle(
                      color: text,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 12,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'finance.income.fromLastMonth'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'finance.income.lastMonthComparison'.trParams({
                    'amount': FinanceMoneyFormatter.format(
                      previousAmount,
                      currency,
                    ),
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Right side: 6-Month Mini Bar Chart
          _MiniBarChart(
            compactBadge: compactValue,
            muted: muted,
          ),
        ],
      ),
    );
  }

  String _compactMoney(double amount, FinanceCurrency currency) {
    final sym = currency == FinanceCurrency.usd ? r'$' : '៛';
    if (amount >= 1000000000) {
      return '$sym${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '$sym${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '$sym${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$sym${amount.toStringAsFixed(0)}';
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({
    required this.compactBadge,
    required this.muted,
  });

  final String compactBadge;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    const months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];
    const fractions = [0.28, 0.42, 0.60, 0.72, 0.85, 1.0];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Floating highlighted badge for the current month
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            compactBadge,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(6, (index) {
              final isCurrent = index == 5;
              final fraction = fractions[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 13,
                      height: 38 * fraction,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFF10B981)
                            : const Color(0xFF10B981).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      months[index],
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFF10B981) : muted,
                        fontSize: 8.5,
                        fontWeight:
                            isCurrent ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _IncomeBySourceSection extends StatelessWidget {
  const _IncomeBySourceSection({
    required this.incomes,
    required this.totalIncome,
    required this.currency,
    required this.selectedSource,
    required this.onSelectSource,
    required this.onToggleSearch,
    required this.searchController,
    required this.showSearch,
    required this.onClearFilter,
    required this.onApplySearch,
    required this.surface,
    required this.surfaceSecondary,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
  });

  final List<FinanceIncomeEntity> incomes;
  final double totalIncome;
  final FinanceCurrency currency;
  final String? selectedSource;
  final ValueChanged<String> onSelectSource;
  final VoidCallback onToggleSearch;
  final TextEditingController searchController;
  final bool showSearch;
  final VoidCallback onClearFilter;
  final VoidCallback onApplySearch;
  final Color surface;
  final Color surfaceSecondary;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    // Group incomes by source
    final Map<String, double> sourceMap = {};
    for (final inc in incomes) {
      final src = (inc.source != null && inc.source!.trim().isNotEmpty)
          ? inc.source!.trim()
          : 'Others';
      sourceMap[src] = (sourceMap[src] ?? 0.0) + inc.amount;
    }

    final sortedEntries = sourceMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'finance.income.bySource'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            GestureDetector(
              onTap: onToggleSearch,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'finance.income.seeAll'.tr,
                  style: TextStyle(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (selectedSource != null || showSearch) ...[
          const SizedBox(height: 10),
          _ActiveFilterOrSearch(
            controller: searchController,
            selectedSource: selectedSource,
            onClear: onClearFilter,
            onApply: onApplySearch,
            surface: surface,
            border: border,
            text: text,
            muted: muted,
            primary: primary,
          ),
        ],
        const SizedBox(height: 12),

        if (sortedEntries.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Center(
              child: Text(
                'finance.income.empty'.tr,
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ),
          )
        else
          ...sortedEntries.take(4).map((entry) {
            final sourceName = entry.key;
            final amount = entry.value;
            final ratio = totalIncome > 0
                ? (amount / totalIncome).clamp(0.0, 1.0)
                : 0.0;
            final percentage = (ratio * 100).round();
            final isSelected = selectedSource == sourceName;
            final info = _SourceMeta.fromSource(sourceName);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelectSource(sourceName),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primary : border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: info.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              info.icon,
                              color: info.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        sourceName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: text,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 5,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          FinanceMoneyFormatter.format(
                                            amount,
                                            currency,
                                          ),
                                          style: TextStyle(
                                            color: text,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: muted,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 6,
                                    backgroundColor:
                                        info.color.withValues(alpha: 0.12),
                                    valueColor: AlwaysStoppedAnimation(
                                      info.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ActiveFilterOrSearch extends StatelessWidget {
  const _ActiveFilterOrSearch({
    required this.controller,
    required this.selectedSource,
    required this.onClear,
    required this.onApply,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.primary,
  });

  final TextEditingController controller;
  final String? selectedSource;
  final VoidCallback onClear;
  final VoidCallback onApply;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    if (selectedSource != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_alt_outlined, size: 16, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'finance.income.filterActive'.trParams({
                  'source': selectedSource!,
                }),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: primary),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: text, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'finance.income.sourceFilterHint'.tr,
                hintStyle: TextStyle(color: muted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: muted),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onApply(),
            ),
          ),
          ElevatedButton(
            onPressed: onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'finance.income.apply'.tr,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentIncomeSection extends StatelessWidget {
  const _RecentIncomeSection({
    required this.incomes,
    required this.currency,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.onTapIncome,
  });

  final List<FinanceIncomeEntity> incomes;
  final FinanceCurrency currency;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final ValueChanged<FinanceIncomeEntity> onTapIncome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'finance.income.recent'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Text(
              'finance.income.seeAll'.tr,
              style: TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (incomes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Center(
              child: Text(
                'finance.income.empty'.tr,
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ),
          )
        else
          ...incomes.map((income) {
            final info = _SourceMeta.fromSource(income.source ?? income.title);
            final formattedDate = _formatDate(income.incomeDate);
            final subtitleParts = [
              if (income.source != null && income.source!.trim().isNotEmpty)
                income.source!.trim()
              else
                'Others',
              formattedDate,
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onTapIncome(income),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: info.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          info.icon,
                          color: info.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              income.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleParts.join(' · '),
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
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '+${FinanceMoneyFormatter.format(income.amount, income.currency)}',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: muted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(String rawDate) {
    try {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
      }
    } catch (_) {}
    return rawDate;
  }
}

class _SmartInsightCard extends StatelessWidget {
  const _SmartInsightCard({
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
  });

  final Color surface;
  final Color border;
  final Color text;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'finance.income.smartInsight'.tr,
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'finance.income.smartInsightDesc'.tr,
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
          Icon(
            Icons.chevron_right_rounded,
            color: muted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _PaginationError extends StatelessWidget {
  const _PaginationError({
    required this.message,
    required this.onRetry,
    required this.textMuted,
  });

  final String message;
  final VoidCallback onRetry;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(onPressed: onRetry, child: Text('common.retry'.tr)),
        ],
      ),
    );
  }
}

class _SourceMeta {
  final IconData icon;
  final Color color;

  const _SourceMeta(this.icon, this.color);

  static _SourceMeta fromSource(String source) {
    final lower = source.toLowerCase();
    if (lower.contains('salary') ||
        lower.contains('job') ||
        lower.contains('payroll') ||
        lower.contains('wage')) {
      return const _SourceMeta(
        Icons.business_center_rounded,
        Color(0xFF10B981),
      );
    }
    if (lower.contains('business') ||
        lower.contains('trade') ||
        lower.contains('invest') ||
        lower.contains('profit')) {
      return const _SourceMeta(
        Icons.trending_up_rounded,
        Color(0xFF2563EB),
      );
    }
    if (lower.contains('gift') ||
        lower.contains('birthday') ||
        lower.contains('bonus') ||
        lower.contains('reward')) {
      return const _SourceMeta(
        Icons.card_giftcard_rounded,
        Color(0xFF8B5CF6),
      );
    }
    if (lower.contains('allowance') ||
        lower.contains('pocket') ||
        lower.contains('family')) {
      return const _SourceMeta(
        Icons.account_balance_wallet_rounded,
        Color(0xFFF59E0B),
      );
    }
    return const _SourceMeta(
      Icons.more_horiz_rounded,
      Color(0xFF64748B),
    );
  }
}
