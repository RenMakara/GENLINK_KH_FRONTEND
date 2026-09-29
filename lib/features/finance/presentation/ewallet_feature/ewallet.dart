import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/widgets/buttons/app_back_button.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_payment_scanner.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/design_system/shadows/app_shadows.dart';
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
    final semantic = context.semanticColors;
    final bg = semantic.background;
    final surface = semantic.surface;
    final border = semantic.borderSubtle;
    final textPrimary = semantic.primaryText;
    final textSecondary = semantic.secondaryText;
    final textMuted = semantic.textMuted;

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
              // Top Bar Header
              Container(
                color: bg,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'finance.ewallet.title'.tr,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'finance.ewallet.subtitle'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showWalletOptions(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: border),
                          boxShadow: isDark
                              ? AppShadows.cardDark
                              : AppShadows.cardLight,
                        ),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          color: textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Wallet Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  color: AppColors.brandPrimary,
                  child: _WalletContent(
                    controller: controller,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showWalletOptions(BuildContext context) {
    final semantic = context.semanticColors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: semantic.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: semantic.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'common.retry'.tr,
                    style: TextStyle(
                      color: semantic.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    controller.refresh();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.financeAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.financeAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'finance.ewallet.historyAction'.tr,
                    style: TextStyle(
                      color: semantic.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.growthAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppColors.growthAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'finance.ewallet.security'.tr,
                    style: TextStyle(
                      color: semantic.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'finance.ewallet.securityNotice'.tr,
                    style: TextStyle(color: semantic.textMuted, fontSize: 12),
                  ),
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WalletContent extends StatefulWidget {
  const _WalletContent({
    required this.controller,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final EWalletController controller;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  @override
  State<_WalletContent> createState() => _WalletContentState();
}

class _WalletContentState extends State<_WalletContent> {
  bool _isBalanceHidden = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final semantic = context.semanticColors;
    final surface = semantic.surface;
    final border = semantic.borderSubtle;
    final textPrimary = widget.textPrimary;
    final textSecondary = widget.textSecondary;
    final textMuted = widget.textMuted;
    final currency = widget.controller.selectedCurrency.value;
    final transactions = widget.controller.visibleTransactions.take(5).toList();
    final refreshError =
        widget.controller.walletErrorMessage.value ??
        widget.controller.historyErrorMessage.value;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
      children: [
        // 1. HERO WALLET CARD
        _WalletHeroCard(
          controller: widget.controller,
          currency: currency,
          isDark: isDark,
          isBalanceHidden: _isBalanceHidden,
          onToggleBalanceHidden: () {
            setState(() {
              _isBalanceHidden = !_isBalanceHidden;
            });
          },
        ),

        if (refreshError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    refreshError,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.controller.refresh,
                  child: Text('common.retry'.tr),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // 2. PRIMARY ACTIONS ROW (Pay, Send, Top Up, History)
        _PrimaryActionsRow(
          isDark: isDark,
          onPay: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
          ),
          onSend: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('finance.ewallet.sendUnavailable'.tr)),
            ),
          onTopUp: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const TopUpWalletScreen()),
          ),
          onHistory: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const TransactionsScreen()),
          ),
        ),

        const SizedBox(height: 22),

        // 3. QUICK ACTIONS SECTION
        _QuickActionsSection(
          isDark: isDark,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textMuted: textMuted,
          onActionTap: (label) => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('finance.ewallet.featureComingSoon'.tr)),
            ),
        ),

        const SizedBox(height: 20),

        // 4. SUMMARY METRICS ROW (Total Incoming, Total Spending)
        _SummarySection(
          controller: widget.controller,
          currency: currency,
          isDark: isDark,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
        ),

        const SizedBox(height: 22),

        // 5. RECENT TRANSACTIONS
        _RecentTransactionsSection(
          controller: widget.controller,
          transactions: transactions,
          isDark: isDark,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          onSeeAll: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const TransactionsScreen()),
          ),
        ),

        const SizedBox(height: 18),

        // 6. DEMO WALLET NOTICE
        _DemoNoticeCard(
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        const SizedBox(height: 16),

        // 7. WALLET SECURITY CARD
        _WalletSecurityCard(
          isDark: isDark,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO WALLET CARD
// ─────────────────────────────────────────────────────────────────────────────
class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({
    required this.controller,
    required this.currency,
    required this.isDark,
    required this.isBalanceHidden,
    required this.onToggleBalanceHidden,
  });

  final EWalletController controller;
  final FinanceCurrency currency;
  final bool isDark;
  final bool isBalanceHidden;
  final VoidCallback onToggleBalanceHidden;

  @override
  Widget build(BuildContext context) {
    // Elegant theme gradients inspired by the reference design
    final cardGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2620), Color(0xFF0C1F1B), Color(0xFF081412)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F2FE), Color(0xFFDEF0FE), Color(0xFFD4E7FC)],
          );

    final borderColor = isDark
        ? const Color(0xFF1B3D34)
        : const Color(0xFFCCE2F8);

    final cardShadow = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ];

    final textTitleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSubColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    final balanceValue = controller.balanceFor(currency);
    final formattedBalance = FinanceMoneyFormatter.format(
      balanceValue,
      currency,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: cardGradient,
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: cardShadow,
      ),
      child: Stack(
        children: [
          // Background organic curves
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: 40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.05)
                    : const Color(0xFF60A5FA).withValues(alpha: 0.07),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Wallet Icon + Name + Primary Badge + Currency Selector
                Row(
                  children: [
                    // Squircle Wallet Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF10B981).withValues(alpha: 0.18)
                            : const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Demo Wallet Label
                    Flexible(
                      child: Text(
                        'finance.ewallet.demoWallet'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textTitleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Primary Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF14532D).withValues(alpha: 0.6)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'finance.ewallet.primaryBadge'.tr,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF16A34A),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // USD / KHR Segmented Toggle Pill
                    _CurrencySelector(
                      currency: currency,
                      onSelected: controller.selectCurrency,
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Available Balance Header Row
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'finance.ewallet.availableBalanceTitle'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textSubColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onToggleBalanceHidden,
                      child: Icon(
                        isBalanceHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: textSubColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionsScreen(),
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: textSubColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Large Balance Amount
                controller.isWalletLoading.value &&
                        controller.wallet.value == null
                    ? const SizedBox(
                        height: 42,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: isBalanceHidden
                                ? ClipRRect(
                                    key: const ValueKey(
                                      'ewallet_balance_blurred',
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                        tileMode: TileMode.decal,
                                      ),
                                      child: Text(
                                        formattedBalance,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: textTitleColor,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1.2,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    formattedBalance,
                                    key: const ValueKey(
                                      'ewallet_balance_visible',
                                    ),
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: textTitleColor,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// CURRENCY SELECTOR PILL
// ─────────────────────────────────────────────────────────────────────────────
class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.currency,
    required this.onSelected,
    required this.isDark,
  });

  final FinanceCurrency currency;
  final ValueChanged<FinanceCurrency> onSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final pillBg = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.6);
    final activeBg = isDark ? Colors.white : const Color(0xFF2563EB);
    final activeFg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveFg = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: FinanceCurrency.values
            .map((option) {
              final isSelected = option == currency;
              return GestureDetector(
                onTap: isSelected ? null : () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    option.apiValue,
                    style: TextStyle(
                      color: isSelected ? activeFg : inactiveFg,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
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

// ─────────────────────────────────────────────────────────────────────────────
// PRIMARY ACTIONS ROW (Pay, Send, Top Up, History)
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryActionsRow extends StatelessWidget {
  const _PrimaryActionsRow({
    required this.isDark,
    required this.onPay,
    required this.onSend,
    required this.onTopUp,
    required this.onHistory,
  });

  final bool isDark;
  final VoidCallback onPay;
  final VoidCallback onSend;
  final VoidCallback onTopUp;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pay Action
        Expanded(
          child: WalletAction(
            icon: Icons.qr_code_scanner_rounded,
            title: 'finance.ewallet.pay'.tr,
            background: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFEFF6FF),
            foreground: isDark
                ? const Color(0xFF60A5FA)
                : const Color(0xFF2563EB),
            onTap: onPay,
          ),
        ),
        const SizedBox(width: 10),

        // Send Action
        Expanded(
          child: WalletAction(
            icon: Icons.send_rounded,
            title: 'finance.ewallet.send'.tr,
            background: isDark
                ? const Color(0xFF2E1065).withValues(alpha: 0.45)
                : const Color(0xFFFAF5FF),
            foreground: isDark
                ? const Color(0xFFC084FC)
                : const Color(0xFF9333EA),
            onTap: onSend,
          ),
        ),
        const SizedBox(width: 10),

        // Top Up Action
        Expanded(
          child: WalletAction(
            icon: Icons.add_circle_outline_rounded,
            title: 'finance.ewallet.topUp'.tr,
            background: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                : const Color(0xFFECFDF5),
            foreground: isDark
                ? const Color(0xFF34D399)
                : const Color(0xFF059669),
            onTap: onTopUp,
          ),
        ),
        const SizedBox(width: 10),

        // History Action
        Expanded(
          child: WalletAction(
            icon: Icons.history_rounded,
            title: 'finance.ewallet.historyAction'.tr,
            background: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            foreground: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
            onTap: onHistory,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS SECTION (Add Card, Request Money, Transfer to Bank, Bill Payment)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.onActionTap,
  });

  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final ValueChanged<String> onActionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'finance.ewallet.quickActions'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onActionTap('See All'),
              child: Text(
                'finance.ewallet.seeAll'.tr,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 4 Action Cards
        Row(
          children: [
            // Add Card
            Expanded(
              child: WalletQuickActionCard(
                icon: Icons.credit_card_rounded,
                title: 'finance.ewallet.addCard'.tr,
                iconColor: isDark
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFF2563EB),
                iconBg: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEFF6FF),
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                onTap: () => onActionTap('Add Card'),
              ),
            ),
            const SizedBox(width: 8),

            // Request Money
            Expanded(
              child: WalletQuickActionCard(
                icon: Icons.arrow_downward_rounded,
                title: 'finance.ewallet.requestMoney'.tr,
                iconColor: isDark
                    ? const Color(0xFF34D399)
                    : const Color(0xFF059669),
                iconBg: isDark
                    ? const Color(0xFF064E3B).withValues(alpha: 0.45)
                    : const Color(0xFFECFDF5),
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                onTap: () => onActionTap('Request Money'),
              ),
            ),
            const SizedBox(width: 8),

            // Transfer to Bank
            Expanded(
              child: WalletQuickActionCard(
                icon: Icons.account_balance_rounded,
                title: 'finance.ewallet.transferToBank'.tr,
                iconColor: isDark
                    ? const Color(0xFFC084FC)
                    : const Color(0xFF9333EA),
                iconBg: isDark
                    ? const Color(0xFF2E1065).withValues(alpha: 0.45)
                    : const Color(0xFFFAF5FF),
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                onTap: () => onActionTap('Transfer to Bank'),
              ),
            ),
            const SizedBox(width: 8),

            // Bill Payment
            Expanded(
              child: WalletQuickActionCard(
                icon: Icons.receipt_long_rounded,
                title: 'finance.ewallet.billPayment'.tr,
                iconColor: isDark
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFFD97706),
                iconBg: isDark
                    ? const Color(0xFF451A03).withValues(alpha: 0.45)
                    : const Color(0xFFFFFBEB),
                surface: surface,
                border: border,
                textPrimary: textPrimary,
                onTap: () => onActionTap('Bill Payment'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY SECTION (Total Incoming & Total Spending)
// ─────────────────────────────────────────────────────────────────────────────
class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.controller,
    required this.currency,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final EWalletController controller;
  final FinanceCurrency currency;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final incomingFormatted = FinanceMoneyFormatter.format(
      controller.recentCredits,
      currency,
    );
    final spendingFormatted = FinanceMoneyFormatter.format(
      controller.recentDebits,
      currency,
    );

    return Row(
      children: [
        // Total Incoming
        Expanded(
          child: WalletSummaryCard(
            title: 'finance.ewallet.totalIncoming'.tr,
            value: '+$incomingFormatted',
            subtitle: 'finance.ewallet.thisMonth'.tr,
            icon: Icons.arrow_outward_rounded,
            iconColor: isDark
                ? const Color(0xFF34D399)
                : const Color(0xFF16A34A),
            iconBg: isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                : const Color(0xFFDCFCE7),
            valueColor: isDark
                ? const Color(0xFF34D399)
                : const Color(0xFF16A34A),
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
        ),
        const SizedBox(width: 12),

        // Total Spending
        Expanded(
          child: WalletSummaryCard(
            title: 'finance.ewallet.totalSpending'.tr,
            value: spendingFormatted,
            subtitle: 'finance.ewallet.thisMonth'.tr,
            icon: Icons.arrow_downward_rounded,
            iconColor: isDark
                ? const Color(0xFFF87171)
                : const Color(0xFFDC2626),
            iconBg: isDark
                ? const Color(0xFF450A0A).withValues(alpha: 0.5)
                : const Color(0xFFFEE2E2),
            valueColor: textPrimary,
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT TRANSACTIONS SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.controller,
    required this.transactions,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onSeeAll,
  });

  final EWalletController controller;
  final List<FinanceWalletTransactionEntity> transactions;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'finance.ewallet.recentTransactions'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'finance.ewallet.seeAll'.tr,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // List Container Card
        _buildTransactionCard(context),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context) {
    if (controller.isHistoryLoading.value && transactions.isEmpty) {
      return Container(
        height: 130,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (var index = 0; index < transactions.length; index++) ...[
            WalletTransaction(
              data: walletTransactionData(
                transactions[index],
                controller.selectedCurrency.value,
                textPrimary,
              ),
              background: _transactionBgColor(transactions[index], isDark),
              textPrimary: textPrimary,
              textMuted: textMuted,
              onTap: onSeeAll,
            ),
            if (index != transactions.length - 1)
              Divider(height: 1, thickness: 0.8, color: border),
          ],
        ],
      ),
    );
  }

  Color _transactionBgColor(
    FinanceWalletTransactionEntity transaction,
    bool isDark,
  ) {
    final type = transaction.transactionType.toUpperCase();
    final debit = transaction.direction.toUpperCase() != 'CREDIT';

    if (!debit) {
      return isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.45)
          : const Color(0xFFECFDF5);
    }

    return switch (type) {
      'EXPENSE' =>
        isDark
            ? const Color(0xFF450A0A).withValues(alpha: 0.45)
            : const Color(0xFFFEE2E2),
      'KHQR_PAYMENT' =>
        isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
      'EVENT_PAYMENT' =>
        isDark
            ? const Color(0xFF2E1065).withValues(alpha: 0.4)
            : const Color(0xFFFAF5FF),
      _ => isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO NOTICE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DemoNoticeCard extends StatelessWidget {
  const _DemoNoticeCard({
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF064E3B).withValues(alpha: 0.25)
        : const Color(0xFFEFF6FF);
    final border = isDark
        ? const Color(0xFF047857).withValues(alpha: 0.4)
        : const Color(0xFFBFDBFE);
    final iconBg = isDark
        ? const Color(0xFF047857).withValues(alpha: 0.4)
        : const Color(0xFFDBEAFE);
    final iconColor = isDark
        ? const Color(0xFF34D399)
        : const Color(0xFF2563EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline_rounded, color: iconColor, size: 22),
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
                const SizedBox(height: 4),
                Text(
                  'finance.ewallet.simulatedNotice'.tr,
                  style: TextStyle(
                    color: textSecondary,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// WALLET SECURITY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _WalletSecurityCard extends StatelessWidget {
  const _WalletSecurityCard({
    required this.isDark,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final bool isDark;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.lock_outline_rounded, color: textMuted, size: 21),
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
                const SizedBox(height: 3),
                Text(
                  'finance.ewallet.securityNotice'.tr,
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER METHODS (Backwards-compatible)
// ─────────────────────────────────────────────────────────────────────────────
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
    iconColor: debit ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
    amountColor: debit ? textPrimary : const Color(0xFF16A34A),
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
