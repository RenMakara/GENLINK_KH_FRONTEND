import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/ewallet_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_localization.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _filterKeys = [
    'finance.ewallet.all',
    'finance.ewallet.payments',
    'finance.ewallet.credits',
    'finance.ewallet.debits',
  ];

  late final EWalletController _walletController;
  late final ScrollController _scrollController;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _walletController = Get.find<EWalletController>();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
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
    final transactions = _walletController.visibleTransactions;
    return switch (_selectedFilter) {
      1 =>
        transactions
            .where(
              (transaction) =>
                  transaction.transactionType.toUpperCase() == 'KHQR_PAYMENT' ||
                  transaction.transactionType.toUpperCase() == 'EVENT_PAYMENT',
            )
            .toList(growable: false),
      2 =>
        transactions
            .where(
              (transaction) => transaction.direction.toUpperCase() == 'CREDIT',
            )
            .toList(growable: false),
      3 =>
        transactions
            .where(
              (transaction) => transaction.direction.toUpperCase() == 'DEBIT',
            )
            .toList(growable: false),
      _ => transactions,
    };
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
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final textInverse = isDark
        ? AppColors.darkTextInverse
        : AppColors.lightTextInverse;
    final border = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'finance.ewallet.transactionTitle'.trParams({
                            'currency': _walletController
                                .selectedCurrency
                                .value
                                .apiValue,
                          }),
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterKeys.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final selected = _selectedFilter == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? primary : surface,
                              borderRadius: BorderRadius.circular(20),
                              border: selected
                                  ? null
                                  : Border.all(color: border),
                            ),
                            child: Text(
                              _filterKeys[index].tr,
                              style: TextStyle(
                                color: selected ? textInverse : textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final transactions = _filteredTransactions();
                final historyError =
                    _walletController.historyErrorMessage.value;
                final loading = _walletController.isHistoryLoading.value;
                if (loading && _walletController.transactions.isEmpty) {
                  return const AppLoader();
                }
                if (historyError != null &&
                    _walletController.transactions.isEmpty) {
                  return AppEmptyState(
                    message: historyError,
                    icon: Icons.history_rounded,
                    action: AppButton.secondary(
                      label: 'common.retry'.tr,
                      onPressed: _walletController.refresh,
                    ),
                  );
                }
                if (transactions.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _walletController.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        const SizedBox(height: 140),
                        AppEmptyState(
                          message: _walletController.hasNextPage.value
                              ? 'finance.ewallet.noMatchingTransactions'.tr
                              : 'finance.ewallet.noTransactions'.tr,
                          icon: Icons.receipt_long_outlined,
                          action: _walletController.hasNextPage.value
                              ? AppButton.text(
                                  label: 'finance.ewallet.loadMore'.tr,
                                  onPressed: _walletController.loadNextPage,
                                )
                              : null,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _walletController.refresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount:
                        transactions.length +
                        (_walletController.isLoadingMore.value ? 1 : 0) +
                        (historyError != null ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= transactions.length) {
                        if (_walletController.isLoadingMore.value) {
                          return const Padding(
                            padding: EdgeInsets.all(18),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            historyError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      final transaction = transactions[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: surfaceSecondary,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                _transactionIconFor(transaction),
                                size: 20,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _transactionTitleFor(transaction),
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _transactionSubtitleFor(transaction),
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              FinanceMoneyFormatter.signed(
                                transaction.amount,
                                transaction.currency,
                                debit:
                                    transaction.direction.toUpperCase() !=
                                    'CREDIT',
                              ),
                              style: TextStyle(
                                color:
                                    transaction.direction.toUpperCase() ==
                                        'CREDIT'
                                    ? AppColors.financeAccent
                                    : textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

String _transactionTitleFor(FinanceWalletTransactionEntity transaction) =>
    financeTransactionTypeText(transaction.transactionType);

String _transactionSubtitleFor(FinanceWalletTransactionEntity transaction) {
  final description = transaction.description?.trim();
  final status = transaction.status.toUpperCase();
  final date = transaction.createdAt?.trim();
  return [
    if (description != null && description.isNotEmpty) description,
    if (date != null && date.isNotEmpty) date,
    if (status != 'SUCCESS') status,
  ].join(' · ').ifEmpty(transaction.currency.apiValue);
}

IconData _transactionIconFor(FinanceWalletTransactionEntity transaction) {
  return switch (transaction.transactionType.toUpperCase()) {
    'KHQR_PAYMENT' => Icons.qr_code_2_rounded,
    'EVENT_PAYMENT' => Icons.event_available_outlined,
    'DEPOSIT' => Icons.add_circle_outline_rounded,
    'REWARD' => Icons.card_giftcard_outlined,
    'EXPENSE' => Icons.receipt_long_outlined,
    'INCOME' => Icons.trending_up_rounded,
    'SAVING' => Icons.savings_outlined,
    _ => Icons.account_balance_wallet_outlined,
  };
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
