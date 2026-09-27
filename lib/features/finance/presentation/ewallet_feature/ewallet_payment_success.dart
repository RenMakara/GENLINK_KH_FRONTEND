import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_transaction.dart';
import 'package:genlink_frontend/features/finance/presentation/formatters/finance_money_formatter.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({
    super.key,
    this.amount,
    this.merchant,
    this.currency,
  });

  final double? amount;
  final String? merchant;
  final FinanceCurrency? currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // COLORS
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

    const success = AppColors.financeAccent;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            children: [
              // SUCCESS ICON
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success.withValues(alpha: 0.10),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: success,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TITLE
              Text(
                'finance.ewallet.paymentSuccessTitle'.tr,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 4),

              // DESCRIPTION
              Text(
                'finance.ewallet.paymentSuccessBody'.tr,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textMuted, fontSize: 13, height: 1.35),
              ),

              const SizedBox(height: 16),

              // AMOUNT CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Text(
                      'finance.ewallet.amount'.tr,
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      amount == null || currency == null
                          ? '—'
                          : FinanceMoneyFormatter.format(amount!, currency!),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Success badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: success.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'finance.ewallet.successful'.tr,
                            style: const TextStyle(
                              color: success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // TRANSACTION DETAILS
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'finance.transactions.details'.tr,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Merchant
                            _DetailRow(
                              icon: Icons.storefront_outlined,
                              label: 'finance.ewallet.merchant'.tr,
                              value: merchant ?? '—',
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              surfaceSecondary: surfaceSecondary,
                            ),

                            // Amount
                            _DetailRow(
                              icon: Icons.payments_outlined,
                              label: 'finance.ewallet.amount'.tr,
                              value: amount == null || currency == null
                                  ? '—'
                                  : FinanceMoneyFormatter.format(
                                      amount!,
                                      currency!,
                                    ),
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              surfaceSecondary: surfaceSecondary,
                              valueBold: true,
                            ),

                            // Currency
                            _DetailRow(
                              icon: Icons.language_rounded,
                              label: 'finance.ewallet.currency'.tr,
                              value: currency?.apiValue ?? '—',
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              surfaceSecondary: surfaceSecondary,
                            ),

                            // Status
                            _DetailRow(
                              icon: Icons.verified_outlined,
                              label: 'finance.ewallet.status'.tr,
                              value: 'finance.ewallet.successful'.tr,
                              textPrimary: textPrimary,
                              textMuted: textMuted,
                              surfaceSecondary: surfaceSecondary,
                              valueColor: success,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // VIEW HISTORY BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionsScreen(),
                    ),
                    (route) => route.isFirst,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: textInverse,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'finance.ewallet.viewHistory'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // BACK TO WALLET BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    backgroundColor: surface,
                    side: BorderSide(color: border),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'finance.ewallet.backToWallet'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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

// DETAIL ROW
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textMuted,
    required this.surfaceSecondary,
    this.valueBold = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;

  final Color textPrimary;
  final Color textMuted;
  final Color surfaceSecondary;

  final bool valueBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: surfaceSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: textMuted),
        ),

        const SizedBox(width: 10),

        // Label
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Value
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? textPrimary,
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
