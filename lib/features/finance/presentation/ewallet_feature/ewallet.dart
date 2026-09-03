import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_scanner_screen.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_button.dart';
import 'package:genlink_frontend/design_system/widgets/loaders/app_loader.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/controllers/ewallet_controller.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_top_up.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_transaction.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/widget/ewallet_widget.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_localization.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

class EWalletScreen extends GetView<EWalletController> {
  const EWalletScreen({super.key});

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
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: Obx(() {
        if (controller.isInitialLoading.value &&
            controller.wallet.value == null) {
          return const AppLoader();
        }

        final walletError = controller.walletErrorMessage.value;

        if (controller.wallet.value == null && walletError != null) {
          return AppEmptyState(
            message: walletError,
            icon: Icons.account_balance_wallet_outlined,
            action: AppButton.secondary(
              label: 'common.retry'.tr,
              onPressed: controller.loadInitial,
            ),
          );
        }

        return Scaffold(
          backgroundColor: bg,
          body: Obx(() {
            if (controller.isInitialLoading.value &&
                controller.wallet.value == null) {
              return const AppLoader();
            }

            final walletError = controller.walletErrorMessage.value;

            if (controller.wallet.value == null && walletError != null) {
              return AppEmptyState(
                message: walletError,
                icon: Icons.account_balance_wallet_outlined,
                action: AppButton.secondary(
                  label: 'common.retry'.tr,
                  onPressed: controller.loadInitial,
                ),
              );
            }

            return SafeArea(
              child: Column(
                children: [
                  // HEADER
                  Container(
                    color: bg,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        AppBackButton(),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            'finance.ewallet.title'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: textPrimary,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // WALLET CONTENT
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.refresh,
                      child: _WalletContent(
                        controller: controller,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      }),
    );
  }
}

class _WalletContent extends StatelessWidget {
  const _WalletContent({
    required this.controller,
    required this.textPrimary,
    required this.textSecondary,
  });

  final EWalletController controller;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;
    final surfaceSecondary = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.lightSurfaceSecondary;
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
    final walletAccent = AppColors.financeAccent;
    final currency = controller.selectedCurrency.value;
    final transactions = controller.visibleTransactions.take(4).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -45,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: textInverse.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'finance.ewallet.demoWallet'.tr,
                        style: TextStyle(
                          color: textInverse.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _CurrencySelector(
                        currency: currency,
                        onSelected: controller.selectCurrency,
                        foreground: textInverse,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  controller.isWalletLoading.value &&
                          controller.wallet.value == null
                      ? SizedBox(
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textInverse.withValues(alpha: 0.8),
                          ),
                        )
                      : Text(
                          FinanceMoneyFormatter.format(
                            controller.balanceFor(currency),
                            currency,
                          ),
                          style: TextStyle(
                            color: textInverse,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    'finance.ewallet.availableBalance'.trParams({
                      'currency': currency.apiValue,
                    }),
                    style: TextStyle(
                      color: textInverse.withValues(alpha: 0.55),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: WalletAction(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'finance.ewallet.pay'.tr,
                          background: textInverse.withValues(alpha: 0.12),
                          foreground: textInverse,
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QRScannerScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: WalletAction(
                          icon: Icons.arrow_upward_rounded,
                          title: 'finance.ewallet.send'.tr,
                          background: textInverse.withValues(alpha: 0.12),
                          foreground: textInverse,
                          onTap: () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'finance.ewallet.sendUnavailable'.tr,
                                ),
                              ),
                            ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: WalletAction(
                          icon: Icons.arrow_downward_rounded,
                          title: 'finance.ewallet.topUp'.tr,
                          background: textInverse.withValues(alpha: 0.12),
                          foreground: textInverse,
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TopUpWalletScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: WalletAction(
                          icon: Icons.history_rounded,
                          title: 'finance.ewallet.historyAction'.tr,
                          background: textInverse.withValues(alpha: 0.12),
                          foreground: textInverse,
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: WalletInfoCard(
                title: 'finance.ewallet.recentDebit'.tr,
                value: FinanceMoneyFormatter.format(
                  controller.recentDebits,
                  currency,
                ),
                subtitle: currency.apiValue,
                icon: Icons.trending_down_rounded,
                iconColor: AppColors.growthAccent,
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: WalletInfoCard(
                title: 'finance.ewallet.recentCredit'.tr,
                value: FinanceMoneyFormatter.format(
                  controller.recentCredits,
                  currency,
                ),
                subtitle: currency.apiValue,
                icon: Icons.trending_up_rounded,
                iconColor: walletAccent,
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'finance.ewallet.recentTransactions'.tr,
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const TransactionsScreen()),
              ),
              child: Text(
                'finance.ewallet.seeAll'.tr,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RecentTransactionsCard(
          controller: controller,
          transactions: transactions,
          surface: surface,
          surfaceSecondary: surfaceSecondary,
          border: border,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: walletAccent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: walletAccent.withValues(alpha: 0.30)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: walletAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.financeAccent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'finance.ewallet.demoWallet'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'finance.ewallet.simulatedNotice'.tr,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: textSecondary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'finance.ewallet.security'.tr,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'finance.ewallet.securityNotice'.tr,
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textMuted, size: 21),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({
    required this.controller,
    required this.transactions,
    required this.surface,
    required this.surfaceSecondary,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final EWalletController controller;
  final List<FinanceWalletTransactionEntity> transactions;
  final Color surface;
  final Color surfaceSecondary;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    if (controller.isHistoryLoading.value && transactions.isEmpty) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: const AppLoader(size: 24),
      );
    }

    final error = controller.historyErrorMessage.value;
    if (error != null && transactions.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: AppEmptyState(
          message: error,
          icon: Icons.history_rounded,
          action: AppButton.text(
            label: 'common.retry'.tr,
            onPressed: () => controller.refresh(),
          ),
        ),
      );
    }

    if (transactions.isEmpty) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: AppEmptyState(
          message: 'finance.ewallet.noTransactions'.tr,
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            for (var index = 0; index < transactions.length; index++) ...[
              WalletTransaction(
                data: walletTransactionData(
                  transactions[index],
                  controller.selectedCurrency.value,
                  textPrimary,
                ),
                background: surfaceSecondary,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              if (index != transactions.length - 1)
                Divider(height: 1, thickness: 0.7, color: border),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.currency,
    required this.onSelected,
    required this.foreground,
  });

  final FinanceCurrency currency;
  final ValueChanged<FinanceCurrency> onSelected;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: FinanceCurrency.values
            .map((option) {
              final selected = option == currency;
              return GestureDetector(
                onTap: selected ? null : () => onSelected(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? foreground.withValues(alpha: 0.22) : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    option.apiValue,
                    style: TextStyle(
                      color: foreground.withValues(alpha: selected ? 1 : 0.65),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

WalletTransactionData walletTransactionData(
  FinanceWalletTransactionEntity transaction,
  FinanceCurrency currency,
  Color textPrimary,
) {
  final type = transaction.transactionType.toUpperCase();
  final debit = transaction.direction.toUpperCase() != 'CREDIT';
  final description = transaction.description?.trim();
  final date = _transactionDate(transaction.createdAt);
  final status = transaction.status.toUpperCase();
  final subtitleParts = <String>[
    if (description != null && description.isNotEmpty) description,
    if (status != 'SUCCESS') status,
  ];
  if (date != null) subtitleParts.insert(1, date);
  final subtitle = subtitleParts.join(' · ');

  return WalletTransactionData(
    title: financeTransactionTypeText(type),
    subtitle: subtitle.isEmpty ? currency.apiValue : subtitle,
    amount: FinanceMoneyFormatter.signed(
      transaction.amount,
      currency,
      debit: debit,
    ),
    icon: _transactionIcon(type),
    iconColor: debit ? AppColors.brandPrimary : AppColors.financeAccent,
    amountColor: debit ? textPrimary : AppColors.financeAccent,
  );
}

IconData _transactionIcon(String type) => switch (type) {
  'KHQR_PAYMENT' => Icons.qr_code_2_rounded,
  'EVENT_PAYMENT' => Icons.event_available_outlined,
  'DEPOSIT' => Icons.add_circle_outline_rounded,
  'REWARD' => Icons.card_giftcard_outlined,
  'EXPENSE' => Icons.receipt_long_outlined,
  'INCOME' => Icons.trending_up_rounded,
  'SAVING' => Icons.savings_outlined,
  _ => Icons.account_balance_wallet_outlined,
};

String? _transactionDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} ${local.hour}:$minute';
}
