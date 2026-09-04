import 'dart:async';
import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // LOADING ANIMATION
    _animationController = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 1000),
    );

    _animationController.repeat();
    _timer = Timer(const Duration(seconds: 3), _openSuccessScreen);
  }

  @override
  void dispose() {
    _timer?.cancel();

    _animationController.dispose();

    super.dispose();
  }

  // OPEN SUCCESS SCREEN
  void _openSuccessScreen() {
    if (!mounted) return;

    _animationController.stop();

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

  // BUILD
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

    // SCAFFOLD
    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),

              decoration: BoxDecoration(
                color: surface,

                borderRadius: BorderRadius.circular(28),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  // LOADING ICON
                  AnimatedBuilder(
                    animation: _animationController,

                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 6.283185307,

                        child: child,
                      );
                    },

                    child: Container(
                      width: 88,
                      height: 88,

                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),

                        shape: BoxShape.circle,
                      ),

                      child: Icon(Icons.sync_rounded, color: primary, size: 48),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TITLE
                  Text(
                    'Processing Payment',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: textPrimary,

                      fontSize: 24,

                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // DESCRIPTION
                  Text(
                    'Please wait while we process your payment.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: textMuted,

                      fontSize: 14,

                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // MERCHANT
                  Text(
                    widget.merchant,

                    textAlign: TextAlign.center,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      color: textPrimary,

                      fontSize: 16,

                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // AMOUNT
                  Text(
                    widget.currency == FinanceCurrency.usd
                        ? '\$${widget.amount.toStringAsFixed(2)}'
                        : '${widget.amount.toStringAsFixed(0)} ៛',

                    style: TextStyle(
                      color: textPrimary,

                      fontSize: 30,

                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CIRCULAR LOADING
                  SizedBox(
                    width: 30,
                    height: 30,

                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,

                      color: primary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // DO NOT CLOSE
                  Text(
                    'Please do not close the app',

                    textAlign: TextAlign.center,

                    style: TextStyle(color: textMuted, fontSize: 12),
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
