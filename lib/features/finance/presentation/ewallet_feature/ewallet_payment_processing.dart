import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:genlink_frontend/design_system/colors/app_colors.dart';
import 'package:genlink_frontend/features/finance/domain/entities/finance_entities.dart';
import 'package:genlink_frontend/features/finance/presentation/ewallet_feature/ewallet_payment_success.dart';

class PaymentProcessingScreen extends StatefulWidget {
  final double amount;
  final String merchant;
  final FinanceCurrency currency;

  const PaymentProcessingScreen({
    super.key,
    required this.amount,
    required this.merchant,
    required this.currency,
  });

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // ROTATION ANIMATION
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // PULSE ANIMATION
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // PROGRESS ANIMATION
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    // Simulate payment processing.
    _timer = Timer(const Duration(seconds: 3), _openSuccessScreen);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    _progressController.dispose();

    super.dispose();
  }

  // OPEN SUCCESS SCREEN
  void _openSuccessScreen() {
    if (!mounted) return;

    _rotationController.stop();
    _pulseController.stop();
    _progressController.stop();

    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          amount: widget.amount,
          merchant: widget.merchant,
          currency: widget.currency,
        ),
      ),
    );
  }

  // FORMAT AMOUNT
  String _formatAmount() {
    if (widget.currency == FinanceCurrency.usd) {
      return '\$${widget.amount.toStringAsFixed(2)}';
    }

    return '${widget.amount.toStringAsFixed(0)} ៛';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // COLORS
    final bg = isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary;

    final surface = isDark
        ? AppColors.darkSurfacePrimary
        : AppColors.lightSurfacePrimary;

    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final secondarySurface = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.025);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // BACKGROUND DECORATION
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.055),
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.035),
                ),
              ),
            ),

            // MAIN CONTENT
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.20 : 0.07,
                        ),
                        blurRadius: 35,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // PAYMENT ICON
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _rotationController,
                          _pulseController,
                        ]),
                        builder: (context, child) {
                          final pulse = 1 + (_pulseController.value * 0.035);

                          return Transform.scale(
                            scale: pulse,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primary.withValues(alpha: 0.055),
                                  ),
                                ),

                                Container(
                                  width: 108,
                                  height: 108,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primary.withValues(alpha: 0.10),
                                  ),
                                ),

                                Transform.rotate(
                                  angle:
                                      _rotationController.value * math.pi * 2,
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primary.withValues(alpha: 0.20),
                                          primary.withValues(alpha: 0.07),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: primary.withValues(alpha: 0.18),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.sync_rounded,
                                      color: primary,
                                      size: 42,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 22),

                      // TITLE
                      Text(
                        'finance.ewallet.processingPayment'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 9),

                      // DESCRIPTION
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'finance.ewallet.processingPaymentHint'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // TRANSACTION DETAILS
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: secondarySurface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            // MERCHANT
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: primary,
                                    size: 21,
                                  ),
                                ),

                                const SizedBox(width: 13),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'finance.ewallet.merchant'.tr,
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.merchant,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            Divider(height: 1, color: borderColor),

                            const SizedBox(height: 18),

                            // AMOUNT
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'finance.ewallet.amount'.tr,
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatAmount(),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // PROGRESS
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: _progressController.value,
                                  minHeight: 5,
                                  backgroundColor: primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primary,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    'finance.ewallet.processingPayment'.tr,
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // SECURITY NOTICE
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.055),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'finance.ewallet.doNotCloseApp'.tr,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // GENLINK BRAND
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: primary.withValues(alpha: 0.65),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'GenLink',
                            style: TextStyle(
                              color: textMuted.withValues(alpha: 0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
