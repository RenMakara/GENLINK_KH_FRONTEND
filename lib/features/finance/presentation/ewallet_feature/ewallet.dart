import 'package:flutter/material.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_payment.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_transaction.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/widget/ewallet_widget.dart';

class EWalletScreen extends StatelessWidget {
  const EWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // THEME TOKENS
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
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
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

    // TRANSACTIONS
    final transactions = [
      WalletTransactionData(
        title: 'KHQR Payment',
        subtitle: 'GenLink Event · Today',
        amount: '-\$15.00',
        icon: Icons.qr_code_rounded,
        iconColor: AppColors.brandPrimary,
        amountColor: textPrimary,
      ),
      WalletTransactionData(
        title: 'Demo Top Up',
        subtitle: 'System · Jun 28',
        amount: '+\$200.00',
        icon: Icons.add_card_rounded,
        iconColor: walletAccent,
        amountColor: walletAccent,
      ),
      WalletTransactionData(
        title: 'KHQR Payment',
        subtitle: 'Market · Jun 27',
        amount: '-\$8.50',
        icon: Icons.receipt_long_outlined,
        iconColor: AppColors.growthAccent,
        amountColor: textPrimary,
      ),
      WalletTransactionData(
        title: 'Demo Start Balance',
        subtitle: 'System · Jun 1',
        amount: '+\$5,000.00',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: walletAccent,
        amountColor: walletAccent,
      ),
    ];

    return Scaffold(
      backgroundColor: bg,

      // APP BAR
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'E-Wallet',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Icon(Icons.more_horiz_rounded, color: textPrimary, size: 21),
          ),
        ],
      ),

      // BODY
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WALLET BALANCE CARD
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
                    Positioned(
                      bottom: -70,
                      right: 30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: textInverse.withValues(alpha: 0.04),
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
                              'Demo Wallet',
                              style: TextStyle(
                                color: textInverse.withValues(alpha: 0.65),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: textInverse.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sim_card_outlined,
                                    size: 11,
                                    color: textInverse.withValues(alpha: 0.75),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SIM',
                                    style: TextStyle(
                                      color: textInverse.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$5,000.00',
                          style: TextStyle(
                            color: textInverse,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Available balance',
                          style: TextStyle(
                            color: textInverse.withValues(alpha: 0.55),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Wallet actions
                        Row(
                          children: [
                            Expanded(
                              child: WalletAction(
                                icon: Icons.qr_code_scanner_rounded,
                                title: 'Pay',
                                background: textInverse.withValues(alpha: 0.12),
                                foreground: textInverse,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PayWithKHQRScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: WalletAction(
                                icon: Icons.arrow_upward_rounded,
                                title: 'Send',
                                background: textInverse.withValues(alpha: 0.12),
                                foreground: textInverse,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: WalletAction(
                                icon: Icons.arrow_downward_rounded,
                                title: 'Top Up',
                                background: textInverse.withValues(alpha: 0.12),
                                foreground: textInverse,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: WalletAction(
                                icon: Icons.history_rounded,
                                title: 'History',
                                background: textInverse.withValues(alpha: 0.12),
                                foreground: textInverse,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TransactionsScreen(),
                                    ),
                                  );
                                },
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

              // WALLET INFORMATION
              Row(
                children: [
                  Expanded(
                    child: WalletInfoCard(
                      title: 'This Month',
                      value: '\$248.50',
                      subtitle: 'Spent',
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
                      title: 'Received',
                      value: '\$2,750',
                      subtitle: 'This Month',
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

              // ─────────────────────────────────────────
              // RECENT TRANSACTIONS
              // ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See All',
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

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < transactions.length; i++) ...[
                        WalletTransaction(
                          data: transactions[i],
                          background: surfaceSecondary,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                        ),
                        if (i != transactions.length - 1)
                          Divider(height: 1, thickness: 0.7, color: border),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ─────────────────────────────────────────
              // DEMO NOTICE
              // ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: walletAccent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: walletAccent.withValues(alpha: 0.30),
                  ),
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
                            'Demo Wallet',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'This wallet is simulated for learning '
                            'purposes only. No real money is involved.',
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

              // WALLET SECURITY
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
                            'Wallet Security',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your demo wallet is protected by GenLink.',
                            style: TextStyle(color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: textMuted,
                      size: 21,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}
