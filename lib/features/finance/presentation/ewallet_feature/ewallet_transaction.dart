import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/radius/app_radius.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/ewallet_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/expense_feature/expense_add_screen.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_localization.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:genlink_frontend/features/finance/presentation/income_feature/income_add_screen.dart';
import 'package:get/get.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _filterKeys = [
    'finance.transactions.all',
    'finance.transactions.income',
    'finance.transactions.expense',
    'finance.transactions.transfer',
  ];

  late final EWalletController _walletController;
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  int _selectedFilter = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _walletController = Get.find<EWalletController>();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 160) {
      _walletController.loadNextPage();
    }
  }

  List<FinanceWalletTransactionEntity> _filteredTransactions() {
    var list = _walletController.visibleTransactions;

    // 1. Apply Type/Direction Filter
    list = switch (_selectedFilter) {
      1 =>
        list
            .where(
              (t) =>
                  t.direction.toUpperCase() == 'CREDIT' ||
                  t.transactionType.toUpperCase() == 'INCOME' ||
                  t.transactionType.toUpperCase() == 'DEPOSIT',
            )
            .toList(growable: false),
      2 =>
        list
            .where(
              (t) =>
                  t.direction.toUpperCase() == 'DEBIT' &&
                  t.transactionType.toUpperCase() != 'TRANSFER' &&
                  t.transactionType.toUpperCase() != 'KHQR_PAYMENT' &&
                  t.transactionType.toUpperCase() != 'SAVING' ||
                  t.transactionType.toUpperCase() == 'EXPENSE',
            )
            .toList(growable: false),
      3 =>
        list
            .where(
              (t) =>
                  t.transactionType.toUpperCase() == 'KHQR_PAYMENT' ||
                  t.transactionType.toUpperCase() == 'EVENT_PAYMENT' ||
                  t.transactionType.toUpperCase() == 'TRANSFER' ||
                  t.transactionType.toUpperCase() == 'SAVING',
            )
            .toList(growable: false),
      _ => list,
    };

    // 2. Apply Search Query Filter
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        final title = _transactionTitleFor(t).toLowerCase();
        final desc = (t.description ?? '').toLowerCase();
        final type = t.transactionType.toLowerCase();
        final amount = t.amount.toString();
        return title.contains(query) ||
            desc.contains(query) ||
            type.contains(query) ||
            amount.contains(query);
      }).toList(growable: false);
    }

    return list;
  }

  Map<String, List<FinanceWalletTransactionEntity>> _groupByDate(
    List<FinanceWalletTransactionEntity> transactions,
  ) {
    final Map<String, List<FinanceWalletTransactionEntity>> groups = {};
    for (final transaction in transactions) {
      final key = _formatDateKey(transaction.createdAt);
      groups.putIfAbsent(key, () => []).add(transaction);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = semantic.background;
    final surface = semantic.surface;
    final textPrimary = semantic.primaryText;
    final textSecondary = semantic.secondaryText;
    final textMuted = semantic.textMuted;
    final border = semantic.borderSubtle;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Obx(() {
          final transactions = _filteredTransactions();
          final historyError = _walletController.historyErrorMessage.value;
          final loading = _walletController.isHistoryLoading.value;
          final allVisible = _walletController.visibleTransactions;

          // Calculate Total Income & Total Expenses across visible transactions
          double totalIncome = 0;
          double totalExpenses = 0;
          for (final t in allVisible) {
            if (t.direction.toUpperCase() == 'CREDIT') {
              totalIncome += t.amount.abs();
            } else {
              totalExpenses += t.amount.abs();
            }
          }

          final currency = _walletController.selectedCurrency.value;
          final grouped = _groupByDate(transactions);

          return RefreshIndicator(
            onRefresh: _walletController.refresh,
            color: AppColors.financeAccent,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                // ── 1. Header ─────────────────────────────────────────────────
                _TransactionsHeader(
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  onAdd: () => _showAddActionSheet(context),
                ),
                const SizedBox(height: 16),

                // ── 2. Search & Filter Bar ────────────────────────────────────
                _SearchAndFilterBar(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  onFilterTap: () {
                    setState(() {
                      _selectedFilter = (_selectedFilter + 1) % _filterKeys.length;
                    });
                  },
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 14),

                // ── 3. Filter Chips ───────────────────────────────────────────
                _FilterChipsBar(
                  selectedFilter: _selectedFilter,
                  filterKeys: _filterKeys,
                  onSelect: (index) => setState(() => _selectedFilter = index),
                  surface: surface,
                  border: border,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 18),

                // ── 4. Summary Cards (Total Income & Expenses) ────────────────
                _SummaryCardsRow(
                  totalIncome: totalIncome,
                  totalExpenses: totalExpenses,
                  currency: currency,
                  surface: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 22),

                // ── 5. State Handling / Grouped Transactions List ─────────────
                if (loading && _walletController.transactions.isEmpty)
                  const SizedBox(
                    height: 300,
                    child: AppLoader(),
                  )
                else if (historyError != null && _walletController.transactions.isEmpty)
                  SizedBox(
                    height: 300,
                    child: AppEmptyState(
                      message: historyError,
                      icon: Icons.history_rounded,
                      action: AppButton.secondary(
                        label: 'common.retry'.tr,
                        onPressed: _walletController.refresh,
                      ),
                    ),
                  )
                else if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: AppEmptyState(
                      message: _walletController.hasNextPage.value
                          ? 'finance.ewallet.noMatchingTransactions'.tr
                          : 'finance.transactions.noResults'.tr,
                      icon: Icons.receipt_long_outlined,
                      action: _walletController.hasNextPage.value
                          ? AppButton.text(
                              label: 'finance.ewallet.loadMore'.tr,
                              onPressed: _walletController.loadNextPage,
                            )
                          : null,
                    ),
                  )
                else ...[
                  // Date-grouped transactions
                  ...grouped.entries.map((entry) {
                    final dateKey = entry.key;
                    final items = entry.value;

                    // Daily Net balance
                    double dailyNet = 0;
                    for (final t in items) {
                      if (t.direction.toUpperCase() == 'CREDIT') {
                        dailyNet += t.amount.abs();
                      } else {
                        dailyNet -= t.amount.abs();
                      }
                    }

                    return _DateGroupSection(
                      dateKey: dateKey,
                      dailyNet: dailyNet,
                      currency: currency,
                      items: items,
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      onTapItem: (t) => _showTransactionDetailSheet(context, t),
                    );
                  }),

                  // Pagination loading indicator
                  if (_walletController.isLoadingMore.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),

                  // Pagination error message
                  if (historyError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        historyError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── 6. Motivation / Status Card ─────────────────────────────
                  _MotivationStatusCard(
                    surface: surface,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showAddActionSheet(BuildContext context) {
    final semantic = context.semanticColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: semantic.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: semantic.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'finance.transactions.addTransaction'.tr,
                  style: TextStyle(
                    color: semantic.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _sheetActionTile(
                  icon: Icons.trending_up_rounded,
                  color: AppColors.financeAccent,
                  title: 'finance.income.title'.tr,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const IncomeAddScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _sheetActionTile(
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.danger,
                  title: 'finance.Expense'.tr,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    final semantic = context.semanticColors;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: semantic.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: semantic.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: semantic.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: semantic.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailSheet(
    BuildContext context,
    FinanceWalletTransactionEntity transaction,
  ) {
    final semantic = context.semanticColors;
    final isCredit = transaction.direction.toUpperCase() == 'CREDIT';
    final amountColor = isCredit ? AppColors.financeAccent : AppColors.danger;
    final formattedAmount = FinanceMoneyFormatter.signed(
      transaction.amount,
      transaction.currency,
      debit: !isCredit,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: semantic.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: semantic.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'finance.transactions.details'.tr,
                      style: TextStyle(
                        color: semantic.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: transaction.status.toUpperCase() == 'SUCCESS'
                            ? AppColors.financeAccent.withValues(alpha: 0.15)
                            : AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.status.toUpperCase(),
                        style: TextStyle(
                          color: transaction.status.toUpperCase() == 'SUCCESS'
                              ? AppColors.financeAccent
                              : AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    formattedAmount,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow('Title', _transactionTitleFor(transaction)),
                const Divider(height: 18),
                _detailRow('Type', transaction.transactionType),
                const Divider(height: 18),
                if (transaction.description != null &&
                    transaction.description!.isNotEmpty) ...[
                  _detailRow('Description', transaction.description!),
                  const Divider(height: 18),
                ],
                _detailRow('Date', transaction.createdAt ?? '—'),
                if (transaction.provider != null) ...[
                  const Divider(height: 18),
                  _detailRow('Provider', transaction.provider!),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    final semantic = context.semanticColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: semantic.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: semantic.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateKey(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recent';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr.split('T').first;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }
}

// ── 1. Top Header ─────────────────────────────────────────────────────────────
class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader({
    required this.textPrimary,
    required this.textMuted,
    required this.onAdd,
  });

  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        const AppBackButton(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'finance.transactions.title'.tr,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'finance.transactions.subtitle'.tr,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onAdd,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_rounded,
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 2. Search & Filter Bar ────────────────────────────────────────────────────
class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.searchController,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Search Input Box
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: searchQuery.isNotEmpty
                    ? AppColors.financeAccent.withValues(alpha: 0.45)
                    : border,
                width: searchQuery.isNotEmpty ? 1.2 : 1,
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.financeAccent,
              style: TextStyle(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'finance.transactions.searchPlaceholder'.tr,
                hintStyle: TextStyle(
                  color: textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: textMuted,
                  size: 22,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: onClear,
                        icon: Icon(
                          Icons.close_rounded,
                          color: textMuted,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Filter Action Button
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onFilterTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: textPrimary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 3. Filter Chips Bar ───────────────────────────────────────────────────────
class _FilterChipsBar extends StatelessWidget {
  const _FilterChipsBar({
    required this.selectedFilter,
    required this.filterKeys,
    required this.onSelect,
    required this.surface,
    required this.border,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  final int selectedFilter;
  final List<String> filterKeys;
  final ValueChanged<int> onSelect;
  final Color surface;
  final Color border;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFF34D399) : const Color(0xFF1E293B);
    final activeText = isDark ? const Color(0xFF064E3B) : Colors.white;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filterKeys.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = selectedFilter == index;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelect(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? activeBg : surface,
                borderRadius: BorderRadius.circular(18),
                border: isSelected ? null : Border.all(color: border),
              ),
              child: Text(
                filterKeys[index].tr,
                style: TextStyle(
                  color: isSelected ? activeText : textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 4. Summary Cards Row ──────────────────────────────────────────────────────
class _SummaryCardsRow extends StatelessWidget {
  const _SummaryCardsRow({
    required this.totalIncome,
    required this.totalExpenses,
    required this.currency,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final double totalIncome;
  final double totalExpenses;
  final FinanceCurrency currency;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    const monthTag = 'Sep 2026';
    final incomeFormatted = FinanceMoneyFormatter.format(totalIncome, currency);
    final expenseFormatted = FinanceMoneyFormatter.format(totalExpenses, currency);

    return Row(
      children: [
        // Total Income Card
        Expanded(
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
                    color: AppColors.financeAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: AppColors.financeAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'finance.transactions.totalIncome'.tr,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          incomeFormatted,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthTag,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Total Expenses Card
        Expanded(
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
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.arrow_downward_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'finance.transactions.totalExpenses'.tr,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          expenseFormatted,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthTag,
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 5. Date Group Section ─────────────────────────────────────────────────────
class _DateGroupSection extends StatelessWidget {
  const _DateGroupSection({
    required this.dateKey,
    required this.dailyNet,
    required this.currency,
    required this.items,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTapItem,
  });

  final String dateKey;
  final double dailyNet;
  final FinanceCurrency currency;
  final List<FinanceWalletTransactionEntity> items;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final ValueChanged<FinanceWalletTransactionEntity> onTapItem;

  @override
  Widget build(BuildContext context) {
    final isNetPositive = dailyNet >= 0;
    final netColor = isNetPositive ? AppColors.financeAccent : AppColors.danger;
    final netSign = isNetPositive ? '+' : '-';
    final formattedNet = '$netSign${FinanceMoneyFormatter.format(dailyNet.abs(), currency)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Group Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dateKey,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formattedNet,
                        style: TextStyle(
                          color: netColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Transaction Items in this Date Group
          ...items.map((t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TransactionItemCard(
                transaction: t,
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => onTapItem(t),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TransactionItemCard extends StatelessWidget {
  const _TransactionItemCard({
    required this.transaction,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onTap,
  });

  final FinanceWalletTransactionEntity transaction;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.direction.toUpperCase() == 'CREDIT';
    final amountColor = isCredit ? AppColors.financeAccent : AppColors.danger;
    final sign = isCredit ? '+' : '-';
    final formattedAmount = '$sign${FinanceMoneyFormatter.format(transaction.amount.abs(), transaction.currency)}';

    final categoryTheme = _resolveCategoryTheme(transaction);
    final title = _cleanTitle(transaction);
    final subtitle = _cleanSubtitle(transaction);
    final timeStr = _formatTime(transaction.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            // Themed Category Squircle Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: categoryTheme.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryTheme.icon,
                color: categoryTheme.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr.isNotEmpty ? '$subtitle · $timeStr' : subtitle,
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Keep every amount in the same right-aligned column.
            SizedBox(
              width: 88,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formattedAmount,
                    maxLines: 1,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 18,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanTitle(FinanceWalletTransactionEntity t) {
    final desc = t.description?.trim();
    if (desc != null && desc.contains(':')) {
      final parts = desc.split(':');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    }
    if (desc != null && desc.isNotEmpty) return desc;
    return _transactionTitleFor(t);
  }

  String _cleanSubtitle(FinanceWalletTransactionEntity t) {
    final typeLabel = _typeLabel(t);
    final catLabel = _categoryLabel(t);
    return '$typeLabel · $catLabel';
  }

  String _typeLabel(FinanceWalletTransactionEntity t) {
    if (t.direction.toUpperCase() == 'CREDIT') return 'Income';
    final type = t.transactionType.toUpperCase();
    if (type.contains('PAYMENT') || type.contains('TRANSFER') || type == 'SAVING') {
      return 'Transfer';
    }
    return 'Expense';
  }

  String _categoryLabel(FinanceWalletTransactionEntity t) {
    final text = '${t.description ?? ''} ${t.transactionType}'.toLowerCase();
    if (text.contains('trade') || text.contains('invest')) return 'Investment';
    if (text.contains('car') || text.contains('transport')) return 'Bills';
    if (text.contains('bank') || text.contains('top up')) return 'E-Wallet';
    if (text.contains('electr') || text.contains('utilit')) return 'Utilities';
    if (text.contains('spotify') || text.contains('entertain')) return 'Entertainment';
    if (text.contains('salary') || text.contains('freelance') || text.contains('business')) return 'Business';
    if (text.contains('food') || text.contains('cafe') || text.contains('lunch')) return 'Food';
    if (text.contains('laptop') || text.contains('saving')) return 'Savings';
    return 'General';
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return '';
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  _CategoryTheme _resolveCategoryTheme(FinanceWalletTransactionEntity t) {
    final text = '${t.description ?? ''} ${t.transactionType}'.toLowerCase();
    if (text.contains('trade') || text.contains('invest')) {
      return const _CategoryTheme(Icons.trending_up_rounded, AppColors.financeAccent);
    }
    if (text.contains('car') || text.contains('vehicle')) {
      return const _CategoryTheme(Icons.directions_car_rounded, AppColors.danger);
    }
    if (text.contains('bank') || text.contains('top up') || text.contains('deposit')) {
      return const _CategoryTheme(Icons.account_balance_rounded, AppColors.brandPrimary);
    }
    if (text.contains('electr') || text.contains('utilit') || text.contains('bill')) {
      return const _CategoryTheme(Icons.lightbulb_rounded, AppColors.warning);
    }
    if (text.contains('spotify') || text.contains('entertain') || text.contains('music')) {
      return const _CategoryTheme(Icons.headphones_rounded, Color(0xFF8B5CF6));
    }
    if (text.contains('freelance') || text.contains('salary') || text.contains('business')) {
      return const _CategoryTheme(Icons.work_rounded, AppColors.financeAccent);
    }
    if (text.contains('food') || text.contains('cafe') || text.contains('lunch')) {
      return const _CategoryTheme(Icons.restaurant_rounded, Color(0xFFF97316));
    }
    if (text.contains('saving')) {
      return const _CategoryTheme(Icons.savings_rounded, Color(0xFF6366F1));
    }
    return _defaultThemeFor(t);
  }

  _CategoryTheme _defaultThemeFor(FinanceWalletTransactionEntity t) {
    if (t.direction.toUpperCase() == 'CREDIT') {
      return const _CategoryTheme(Icons.trending_up_rounded, AppColors.financeAccent);
    }
    return const _CategoryTheme(Icons.receipt_long_rounded, AppColors.danger);
  }
}

class _CategoryTheme {
  const _CategoryTheme(this.icon, this.color);
  final IconData icon;
  final Color color;
}

// ── 6. Motivation Status Card ─────────────────────────────────────────────────
class _MotivationStatusCard extends StatelessWidget {
  const _MotivationStatusCard({
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.financeAccent.withValues(
            alpha: isDark ? 0.35 : 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.financeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.financeAccent,
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
                  'finance.transactions.keepTracking'.tr,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'finance.transactions.keepTrackingDesc'.tr,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _transactionTitleFor(FinanceWalletTransactionEntity transaction) =>
    financeTransactionTypeText(transaction.transactionType);
